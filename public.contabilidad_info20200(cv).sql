CREATE OR REPLACE FUNCTION public.contabilidad_info20200(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo   record;
       xnumeroregistro bigint;
       rfactura record;	
       xanio integer;
       elnumeroregistro bigint;
       elanio integer;
       info_prestador record;
       rinfoaux record;
       elid bigint;
       elcentro integer;
       elnuemrorecibo bigint;
	    
BEGIN
       /** Se va devolver en la columna observacion el nombre del prestador agupador si el compobante corresponde a un agrupado
          o el nombre del prestador si no esta agrupado el prestador del comprobante
        */
      info ='';
   ---   RAISE NOTICE 'En el sp contabilidad_info20200(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;
          
          
      IF FOUND THEN
                   IF( rinfo.idasientogenericocomprobtipo = 4)THEN
                       -- Si el asiento corresponde a una minuta de pago
                        elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                        SELECT INTO info_prestador 
                               CASE WHEN  nullvalue(prestador.idcolegio) THEN concat(prestador.idprestador,' @ ', prestador.pdescripcion,' @ ')
                                    ELSE concat(loagrupa.idprestador ,' @ ', loagrupa.pdescripcion,' @ ') END as elprestador
                        FROM ordenpagoprestador
                        JOIN prestador USING (idprestador)
                        LEFT JOIN prestador as loagrupa ON (prestador.idcolegio=loagrupa.idprestador)
                        WHERE nroordenpago = elid and idcentroordenpago = elcentro;
                        if (found) then info = info_prestador.elprestador;
                        else
                              SELECT INTO rinfoaux * from  cuentacorrientedeuda  
                              natural join  cuentacorrientedeudapagoordenpago                             
                              natural join persona
                              where nroordenpago = elid and idcentroordenpago = elcentro;
                    
                              IF (FOUND)THEN
                                    -- info = concat(rinfoaux.nrodoc,' ',rinfoaux.apellido,rinfoaux.nombres);
                                       info = concat(rinfoaux.nrodoc,' @ ',rinfoaux.apellido,rinfoaux.nombres,' @ ');
                              END IF;


                        end if;
               
                   END IF;
                   IF( rinfo.idasientogenericocomprobtipo = 1)THEN
                   -- Si el comprobante se corresponde con una OPC
                        elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                        SELECT INTO info_prestador 
                                    CASE WHEN  nullvalue(prestador.idcolegio) THEN concat(prestador.idprestador ,' @ ', prestador.pdescripcion,' @ ')
                                    ELSE concat(loagrupa.idprestador,' @ ', loagrupa.pdescripcion,' @ ') END as elprestador
                        
                        FROM ordenpagocontable
                        JOIN prestador USING (idprestador)
                        LEFT JOIN prestador as loagrupa ON (prestador.idcolegio=loagrupa.idprestador)
                        WHERE idordenpagocontable = elid and idcentroordenpagocontable = elcentro;
                        info = info_prestador.elprestador;
                   END IF;
                   IF( rinfo.idasientogenericocomprobtipo = 8) THEN
				   		
                       -- Si el asiento corresponde a un recibo 
                        elnuemrorecibo = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
						
			SELECT INTO info_prestador concat('Minuta ',nroordenpago,'|',idcentroordenpago,' Liq ',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta,' ')  as lainfo
			FROM mapeoliquidaciontarjeta 
			NATURAL JOIN liquidaciontarjetaitem
			JOIN recibocupon USING(idrecibocupon,idcentrorecibocupon)
			WHERE idvalorescaja = 959 --Valor Caja 959 es Cupones Merado Pago
			AND recibocupon.idrecibo =elnuemrorecibo AND recibocupon.centro = elcentro;

						
			IF FOUND THEN	  
                         	info = info_prestador.lainfo;
			END IF;
						
                   END IF;
                   
                   IF ( rinfo.idasientogenericocomprobtipo = 5) THEN
                        -- Si el comprobante se corresponde con una factura de venta
                        SELECT  INTO info_prestador concat(cliente.nrocliente,'/', cliente.barra ,' @ ', denominacion,' @ ') as elprestador
                        FROM facturaventa
                        JOIN cliente ON(nrodoc=nrocliente and facturaventa.barra = cliente.barra)
                        WHERE nrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)
                              and tipocomprobante = split_part(rinfo.idcomprobantesiges, '|', 2)
                              and nrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)
                              and tipofactura = split_part(rinfo.idcomprobantesiges, '|', 1);
                        info = info_prestador.elprestador;
                              
                   END IF ;
                   IF ( rinfo.idasientogenericocomprobtipo = 7) THEN
                            -- Si es un comprobante de compra busco la info del prestador
                            elnumeroregistro = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                            elanio = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                            SELECT INTO info_prestador CASE WHEN not nullvalue(r.numeroregistro) THEN concat(r.idprestador ,' @ ', r.pdescripcion,' @ ')
                                   ELSE concat(prestador.idprestador ,' @ ', prestador.pdescripcion,' @ ') END as elprestador
                            FROM reclibrofact 
                            JOIN prestador ON (reclibrofact.idprestador=prestador.idprestador)
                            LEFT JOIN factura  ON (factura.nroregistro = reclibrofact.numeroregistro  and factura.anio = reclibrofact.anio) 
                            LEFT JOIN(
                                 SELECT *
                                 FROM reclibrofact
                                 JOIN prestador USING (idprestador)
                            )as r ON (r.numeroregistro = factura.idresumen AND  r.anio = factura.anioresumen)
                            WHERE reclibrofact.anio = elanio and  reclibrofact.numeroregistro = elnumeroregistro;
                            info = info_prestador.elprestador;
                 END IF;


     IF (rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion de Recibo*/
         select into rinfoaux *
         from cuentacorrientedeuda
         left join recibo on(idcomprobante/100=idrecibo  and centro=idcomprobante%100) 
         left join orden  on(nroorden=idcomprobante/100 and orden.centro=idcomprobante%100)
         left join consumo on(consumo.nroorden=orden.nroorden and consumo.centro=orden.centro)
         left join persona on(persona.nrodoc=cuentacorrientedeuda.nrodoc  and   persona.tipodoc=cuentacorrientedeuda.tipodoc )
         where iddeuda=split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
         and idcentrodeuda=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint;                


          IF (FOUND)THEN   -- si el comprobante es un Recibo
                    info = concat(rinfoaux.nrodoc,' ',rinfoaux.apellido,'',rinfoaux.nombres,'|',rinfoaux.nroorden,'-',rinfoaux.centro);
          END IF;
      END IF;
      END IF;

RETURN info;
END;
$function$
