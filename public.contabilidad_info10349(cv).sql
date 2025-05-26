CREATE OR REPLACE FUNCTION public.contabilidad_info10349(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
	   rinfoaux_2 record;
       xnumeroregistro bigint;
       elnuemrorecibo bigint;
	   elcentro bigint;
	   xanio integer;
	   info_minuta record;
	   vnroordenpago bigint;
	   vidcentroordenpago INTEGER;
	
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
      info ='Sin vincular';
    --  RAISE NOTICE 'En el sp 10349(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h
           --  and idasientogenericocomprobtipo = 5
             ;

      IF (FOUND)THEN

			   IF (rinfo.idasientogenericocomprobtipo = 5) THEN /*Es una Factura de Venta vas 250123*/
			         ---  Se analiza a que tipo de informe de facturacion corresponde
					 ---  4 Solicitud Financiacion  
					 ---  3 Consumo Turismo
					 SELECT   INTO rinfoaux * 
					 FROM informefacturacion 
					 WHERE  nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
					 		AND tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
					 		AND tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
					 		AND nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint;
					 IF (rinfoaux.idinformefacturaciontipo = 4) THEN 
					          ---  La factura se corresponde con un informe de facturacion de una 4 Solicitud Financiacion  		
							  SELECT  INTO rinfoaux_2 * 
					 		  FROM informefacturacion 
							  NATURAL JOIN informefacturacionsolicitudfinanciacion 
							  NATURAL JOIN solicitudfinanciacion 
							  WHERE nroinforme	= rinfoaux.nroinforme
							        AND idcentroinformefacturacion = rinfoaux.idcentroinformefacturacion;
							 IF (FOUND)THEN  
							        --- el factor comun del informe es la solicitud de financiacion
							        info = concat(rinfoaux_2.idprestamo,'|',rinfoaux_2.idcentroprestamo);
						     ELSE 
							        info = ' CASO 1';
							 END IF;
					 END IF;
					 IF (rinfoaux.idinformefacturaciontipo = 3 ) THEN 
							  ---  La factura se corresponde con un informe de facturacion   3 Consumo Turismo	
							  SELECT  INTO rinfoaux_2 * 
					 		  FROM informefacturacion 
							  NATURAL JOIN informefacturacionturismo
							  NATURAL JOIN consumoturismo 
							  WHERE nroinforme	= rinfoaux.nroinforme
							        AND idcentroinformefacturacion = rinfoaux.idcentroinformefacturacion;
							  IF (FOUND)THEN  
							        --- el factor comun del informe es el consumo de turismo
							        info = concat(rinfoaux_2.idprestamo,'|',rinfoaux_2.idcentroprestamo);
							  ELSE 
							          info = ' CASO  2';
						      END IF;
					 END IF;
              END IF;
	         
			 
			   IF( rinfo.idasientogenericocomprobtipo = 4 )THEN --Se trata de una ordenpago
						  SELECT INTO rinfoaux *
						  FROM cuentacorrientedeudapagoordenpago
						  JOIN cuentacorrientedeuda USING (iddeuda,idcentrodeuda)
						  JOIN prestamocuotas  ON ( idcomprobante = concat(idprestamocuotas::varchar,idcentroprestamocuota::varchar)::bigint)
						  WHERE nroordenpago = split_part(rinfo.idcomprobantesiges, '|', 1) 
						         AND idcentroordenpago = split_part(rinfo.idcomprobantesiges, '|', 2);
						  IF FOUND THEN	  
                         		info = concat(rinfoaux.idprestamo,'|',rinfoaux.idcentroprestamo);
						  END IF;
					END IF;
	  
			 
			 
			 
			  IF( rinfo.idasientogenericocomprobtipo = 8) THEN
				   		
                       -- Si el asiento corresponde a un recibo 
                        elnuemrorecibo = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
						
						SELECT INTO info_minuta concat('Minuta ',nroordenpago,'|',idcentroordenpago,' Liq ',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta,' ')  as lainfo
						FROM mapeoliquidaciontarjeta 
						NATURAL JOIN liquidaciontarjetaitem
						JOIN recibocupon USING(idrecibocupon,idcentrorecibocupon)
						WHERE idvalorescaja = 959 --Valor Caja 959 es Cupones Merado Pago
							AND recibocupon.idrecibo =elnuemrorecibo AND recibocupon.centro = elcentro;

						
						 IF FOUND THEN	  
                         		info = info_minuta.lainfo;
						  END IF;
						
                   END IF;
				   
				 
	  
	  
	  
	  
     IF (rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion de Recibo*/
         select into rinfoaux *
         from cuentacorrientedeuda
         left join recibo
         on(idcomprobante/100=idrecibo  and centro=idcomprobante%100) 
         left join orden
         on(nroorden=idcomprobante/100 and orden.centro=idcomprobante%100)
         left join consumo on(consumo.nroorden=orden.nroorden and consumo.centro=orden.centro)
         left join persona on(persona.nrodoc=cuentacorrientedeuda.nrodoc 
         and   persona.tipodoc=cuentacorrientedeuda.tipodoc )
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
