CREATE OR REPLACE FUNCTION public.contabilidad_info10817(character varying)
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
	   
	   info_ccon  record;
	   rreversion record;
BEGIN
       /** Se va devolver en la columna observacion la denominacion del cliente
	   * y el comprobante que se va a utilizar para la conciliacion es el informe facturacion
        */
      info ='Sin vincular';
      -- RAISE NOTICE 'En el sp contabilidad_info10817(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;
         
          
      IF FOUND THEN
	   			 --- Si es una reversion entonces devuelvo el idasientogenerico
           		 SELECT INTO rreversion *
           		 FROM asientogenerico 
           		 NATURAL JOIN asientogenericoitem 
           		 WHERE idasientogenericorevertido = rinfo.idasientogenerico AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           		 IF (FOUND) THEN
                    	info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           		  END IF;  
           		  --- Si esta revertido devuelvo el idasientorevertido
           		  IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    	info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                   
           		   END IF;
	  
	  
                   IF( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 5)THEN
                       		-- Si el asiento corresponde a un comprobante de venta de una liquidacion
                        	SELECT INTO info_ccon concat ('// LIQ:',idliquidacion,'-', idcentroliquidacion ) lainfo
                        	FROM far_ordenventaitemitemfacturaventa fv
                        	JOIN far_liquidacionitemovii USING (idordenventaitem, idcentroordenventaitem)
                        	JOIN far_liquidacionitems USING(idliquidacionitem, idcentroliquidacionitem) 
                        	JOIN far_liquidacionestado USING(idliquidacion, idcentroliquidacion)   
                        	JOIN far_liquidacion USING(idliquidacion, idcentroliquidacion) 
                        	JOIN far_obrasocial USING (idobrasocial)
                        	WHERE nullvalue(lefechafin) AND idestadotipo <> 4 AND nrocuentac = rfiltros.nrocuentac 
                                      AND concat(fv.tipofactura,'|',fv.tipocomprobante,'|',fv.nrosucursal,'|',fv.nrofactura) =rinfo.idcomprobantesiges;
							
				IF FOUND THEN	  
                         		info = info_ccon.lainfo;
				END IF;
                   END IF;

                      IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 8 )THEN  --recibo
                           SELECT INTO info_ccon  text_concatenar (concat ('// LIQ:',idliquidacion,'-', idcentroliquidacion )) as lainfo
                           FROM ctactepagocliente p 
                           NATURAL JOIN clientectacte c
                           JOIN cliente USING (nrocliente,barra)
                           LEFT JOIN ctactedeudapagocliente USING (idpago,idcentropago)
                           LEFT JOIN ctactedeudacliente d USING (iddeuda,idcentrodeuda)
                           LEFT JOIN  informefacturacion if ON (d.idcomprobante = nroinforme*100+idcentroinformefacturacion)
                           LEFT JOIN informefacturacionliqfarmacia USING(nroinforme,idcentroinformefacturacion)    
                           
                           WHERE p.idcomprobante = concat(split_part(rinfo.idcomprobantesiges, '|', 1) )
                                  AND idcentropago = concat(split_part(rinfo.idcomprobantesiges, '|', 2) )
                           GROUP BY idpago,idcentropago;
                           IF FOUND THEN	  
                                info = info_ccon.lainfo;
            
                           END IF;
                     END IF;
                      IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 5 )THEN    
                                 -- factura emitida al cliente
                                SELECT INTO info_ccon  text_concatenar (concat ('// LIQ:',idliquidacion,'-', idcentroliquidacion )) as lainfo
                                FROM facturaventa  as fv
                                JOIN informefacturacion if ON (fv.tipofactura = if.tipofactura 
                                                        AND fv.tipocomprobante = if.tipocomprobante
                                AND fv.nrosucursal = if.nrosucursal 
                                AND fv.nrofactura = if.nrofactura )
                                JOIN ctactepagocliente p ON (p.idcomprobante = if.nroinforme*100+if.idcentroinformefacturacion)
                                LEFT JOIN ctactedeudapagocliente USING (idpago,idcentropago)
                                LEFT JOIN ctactedeudacliente d USING (iddeuda,idcentrodeuda)
                                LEFT JOIN informefacturacion ifd ON (d.idcomprobante = ifd.nroinforme*100+ifd.idcentroinformefacturacion)
                                LEFT JOIN informefacturacionliqfarmacia il ON (ifd.nroinforme = il.nroinforme
                                                AND ifd.idcentroinformefacturacion = il.idcentroinformefacturacion)    
                                WHERE concat(fv.tipofactura,'|',fv.tipocomprobante,'|',fv.nrosucursal,'|',fv.nrofactura) = rinfo.idcomprobantesiges
                                      AND d.idcomprobantetipos=21
                                GROUP BY idpago,idcentropago;
                      IF FOUND THEN	  
                                info = info_ccon.lainfo;
            
                             END IF;
                     END IF;



                     IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 7 )THEN 
                            SELECT INTO info_ccon text_concatenar (concat ('// LIQ:',idliquidacion,'-', idcentroliquidacion )) as lainfo
                            FROM ctactepagocliente p
                            LEFT JOIN ctactedeudapagocliente USING (idpago,idcentropago)
                            LEFT JOIN ctactedeudacliente d USING (iddeuda,idcentrodeuda)
                            LEFT JOIN  informefacturacion if ON (d.idcomprobante = nroinforme*100+idcentroinformefacturacion)
                            LEFT JOIN informefacturacionliqfarmacia USING(nroinforme,idcentroinformefacturacion)    
                            WHERE p.idcomprobante = concat(split_part(rinfo.idcomprobantesiges, '|', 1), split_part(rinfo.idcomprobantesiges, '|', 2)) ::bigint
                             GROUP BY idpago,idcentropago;

                             IF FOUND THEN	  
                                info = info_ccon.lainfo;
            
                             END IF;
                     END IF;

                     
                  
      END IF;
     /* IF nullvalue(info) THEN    
	       info=concat('ERROR idasientogenericoitem=',rinfo.idasientogenericoitem,' idcentroasientogenericoitem=' ,rinfo.idcentroasientogenericoitem);
	  END IF;*/
RETURN info;
END;
$function$
