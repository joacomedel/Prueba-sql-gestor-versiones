CREATE OR REPLACE FUNCTION public.contabilidad_info10253(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo   record;
       xnumeroregistro bigint;
	   elnuemrorecibo bigint;
	    elcentro bigint;
	   
       rfactura record;	
	   elanio integer;
	   elnumeroregistro bigint;
	   
	   info_minuta record;
	   elnrofactura bigint;
	   vnroordenpago bigint;
	   vidcentroordenpago INTEGER;
       eltipocomprobante integer ;
       elnrosucursal integer;
       eltipofactura character varying;
BEGIN
       /** Se va devolver en la columna observacion El nro de Minuta y Nro Liuidacion que se genera para contablicar (cerrar) la liquidacion de tarjetas
	   * Si el comprobante no esta en una liquidacion cerrada se coloca la descripcion 'Sin Liquidacion Cerrada'
        */
      info ='';
      RAISE NOTICE 'En el sp contabilidad_info10377(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;
         
          
      IF FOUND THEN
	  				info = concat('Sin Liquidacion Cerrada |',rinfo.idcomprobantesiges);
	  				IF( rinfo.idasientogenericocomprobtipo = 4 )THEN --Las liquidaciones de tarjeta se contabilizan con una Minuta
						  vnroordenpago = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                          vidcentroordenpago = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
						  SELECT INTO info_minuta concat('Minuta ',nroordenpago,'|',idcentroordenpago,' Liq ',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta,' ') as lainfo
						  FROM mapeoliquidaciontarjeta 
						  WHERE nroordenpago = vnroordenpago AND idcentroordenpago = vidcentroordenpago;
						 
						 IF FOUND THEN	  
                         		info = info_minuta.lainfo;
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
                   IF( rinfo.idasientogenericocomprobtipo = 5
					  -- Lo comento.... no se si hace falta (MaLaPi)
					  --AND  (length(rinfo.idcomprobantesiges) - length(replace(rinfo.idcomprobantesiges,'|','')) =3) 
					 )THEN
                  -- Si el comprobante se corresponde con una facturaventa
				 --  FA|1|1001|4964
				       
                        elnrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)::bigint;
                        eltipocomprobante = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                        elnrosucursal  = split_part(rinfo.idcomprobantesiges, '|', 3)::bigint;
                        eltipofactura = split_part(rinfo.idcomprobantesiges, '|', 1)::character varying; 

                       
                        SELECT INTO info_minuta concat('Minuta ',nroordenpago,'|',idcentroordenpago,' Liq ',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta,' ')  as lainfo
						FROM mapeoliquidaciontarjeta 
						NATURAL JOIN liquidaciontarjetaitem
						NATURAL JOIN facturaventacupon 
						WHERE idvalorescaja = 959 --Valor Caja 959 es Cupones Merado Pago
							AND nrofactura = elnrofactura  AND nrosucursal = elnrosucursal 
							AND tipofactura = eltipofactura AND tipocomprobante = eltipocomprobante;

						
						 IF FOUND THEN	  
                         		info = info_minuta.lainfo;
						  END IF;
                   END IF;
                   
                  
      END IF;
     /* IF nullvalue(info) THEN    
	       info=concat('ERROR idasientogenericoitem=',rinfo.idasientogenericoitem,' idcentroasientogenericoitem=' ,rinfo.idcentroasientogenericoitem);
	  END IF;*/
RETURN info;
END;
$function$
