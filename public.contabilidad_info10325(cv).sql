CREATE OR REPLACE FUNCTION public.contabilidad_info10325(character varying)
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
      -- RAISE NOTICE 'En el sp contabilidad_info10325(%)',$1;
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
           		 WHERE idasientogenericorevertido = rinfo.idasientogenerico 				
				 		AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           		 IF (FOUND) THEN
                    	          info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           		  END IF;  
           		  --- Si esta revertido devuelvo el idasientorevertido
           		  IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    	          info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                   
           		   END IF;
                      
                       IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 8 )THEN  --recibo
                         
                           SELECT INTO info_ccon  concat( '[',nrocliente,'-', c.barra,']',' | ',  denominacion ,text_concatenar(comprobante) ) as lainfo
                           FROM (

                                 SELECT cc.nrocliente,cc.barra, CASE WHEN not nullvalue(dp.iddeuda) THEN concat(' @ ',iddeuda,'|',idcentrodeuda,'|',idpago,'|',idcentropago) ELSE '' END as comprobante
       
                                 FROM recibo 
                                 JOIN ctactepagocliente ON (idcomprobante = idrecibo AND centro=idcentropago) 
                                 JOIN clientectacte cc USING (idclientectacte, idcentroclientectacte)
                                 LEFT JOIN ctactedeudapagocliente dp  USING (idpago,idcentropago)
                                 WHERE idrecibo =split_part(rinfo.idcomprobantesiges, '|', 1) 
                                        AND centro = split_part(rinfo.idcomprobantesiges, '|', 2)

                           ) as T
                            JOIN cliente c USING ( nrocliente,barra)
                           group by nrocliente,c.barra , denominacion;



                           IF FOUND THEN	  
                                info = info_ccon.lainfo;
            
                           END IF;
                     END IF;
                      IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 5 )THEN    
                                 -- factura emitida al cliente
                                 


                               SELECT INTO info_ccon  concat(  '[',nrodoc,'-', c.barra,']',' | ', denominacion,text_concatenar(comprobante) ) as lainfo
                               FROM (

                                     SELECT nrodoc,fv.barra, CASE WHEN not nullvalue(dp.iddeuda) THEN concat(' @ ',iddeuda,'|',idcentrodeuda,'|',idpago,'|',idcentropago) ELSE '' END as comprobante
       
                                     FROM facturaventa fv
                                     JOIN informefacturacion USING(tipofactura,nrosucursal,tipocomprobante,nrofactura)
                                     JOIN cliente c ON(c.nrocliente=nrodoc AND c.barra = fv.barra)
                                     JOIN ctactedeudacliente ON(concat(nroinforme*100+idcentroinformefacturacion) = idcomprobante)
                                     LEFT join ctactedeudapagocliente as dp USING (iddeuda,idcentrodeuda)
                                     WHERE fv.tipofactura = split_part(rinfo.idcomprobantesiges, '|',1 )
                                           AND fv.tipocomprobante  = split_part(rinfo.idcomprobantesiges, '|',2 )
                                           AND fv.nrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)
                                           AND fv.nrofactura = split_part(rinfo.idcomprobantesiges, '|',4 )

                               ) as T
                                JOIN cliente c ON(c.nrocliente=nrodoc AND c.barra = T.barra)
                               group by nrodoc,c.barra , denominacion;




                      IF FOUND THEN	  
                                info = info_ccon.lainfo;
            
                             END IF;
                     END IF;

                
                     
                  
      END IF;
  
RETURN info;
END;
$function$
