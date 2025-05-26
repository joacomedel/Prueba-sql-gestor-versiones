CREATE OR REPLACE FUNCTION public.contabilidad_info10826(character varying)
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
	   
	   info_cliente record;
	   rreversion record;
BEGIN
       /** Se va devolver en la columna observacion la denominacion del cliente
	   * y el comprobante que se va a utilizar para la conciliacion es el informe facturacion
        */
      info ='Sin vincular';
      -- RAISE NOTICE 'En el sp contabilidad_info10826(%)',$1;
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
	  
	  
                   IF( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 8)THEN
                       		-- Si el asiento corresponde a un recibo 
                        	elnuemrorecibo = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        	elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
							info = 'VER No se encontro comprobante';
                        	SELECT INTO info_cliente concat(nrocliente ,' ', denominacion,'|' ,ctactedeudacliente.idcomprobante)  as lainfo
                         	FROM ctactepagocliente
                        	JOIN ctactedeudapagocliente using (idpago,idcentropago)
                        	JOIN ctactedeudacliente using (iddeuda,idcentrodeuda)
				JOIN clientectacte ON (ctactedeudacliente.idclientectacte =  clientectacte.idclientectacte
					               and ctactedeudacliente.idcentroclientectacte =  clientectacte.idcentroclientectacte)
                        	NATURAL JOIN cliente
                        	WHERE ctactepagocliente.idcomprobante= elnuemrorecibo
                              		and ctactepagocliente.idcomprobantetipos = 0 
							  		and idcentropago=elcentro;
				IF FOUND THEN	  
                         		info = info_cliente.lainfo;
				END IF;
                   END IF;
                   IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 5 )THEN
                          -- Si el comprobante se corresponde con una facturaventa
			     	      --  FA|1|1001|4964
                 
                        SELECT INTO info_cliente  concat(cliente.nrocliente ,' ', denominacion,'|' , ctactedeudacliente.idcomprobante) as lainfo
                  	FROM facturaventa
                        JOIN cliente ON  (nrodoc = nrocliente and facturaventa.barra = cliente.barra)
                        JOIN informefacturacion USING(nrofactura,tipocomprobante,nrosucursal,tipofactura)
                        JOIN ctactedeudacliente ON (idcomprobante = nroinforme*100+idcentroinformefacturacion)
			WHERE nrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
                              and  tipocomprobante = split_part(rinfo.idcomprobantesiges, '|', 2)::integer
                              and  nrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)::bigint
                              and  tipofactura = split_part(rinfo.idcomprobantesiges, '|', 1)::character varying;
                        IF FOUND THEN	  
                         		info = info_cliente.lainfo;
							END IF;   
            
                        END IF;
			IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 5 )THEN
                          -- Si el comprobante se corresponde con una facturaventa
			     	      --  'NC|1|1001|5182'
				SELECT INTO info_cliente  concat(cliente.nrocliente ,' ', denominacion,'|' , ctactedeudacliente.idcomprobante) as lainfo
				FROM facturaventa
				JOIN cliente ON  (nrodoc = nrocliente and facturaventa.barra = cliente.barra)
				JOIN informefacturacion USING(nrofactura,tipocomprobante,nrosucursal,tipofactura)
				JOIN ctactepagocliente ON (idcomprobante = nroinforme*100+idcentroinformefacturacion)
				JOIN ctactedeudapagocliente USING (idpago,idcentropago)
				JOIN ctactedeudacliente USING (iddeuda,idcentrodeuda)
				WHERE nrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
                                         and  tipocomprobante = split_part(rinfo.idcomprobantesiges, '|', 2)::integer
                                         and  nrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)::bigint
                                         and  tipofactura = split_part(rinfo.idcomprobantesiges, '|', 1)::character varying;
                                IF FOUND THEN	  
                         		info = info_cliente.lainfo;
			        END IF;   
            
                   END IF;
                   IF( info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 4 )THEN

                              SELECT INTO info_cliente  concat(cliente.nrocliente ,' ', denominacion,'|' , ctactedeudacliente.idcomprobante) as lainfo
                              FROM ctactedeudapagoclienteordenpago
                              JOIN ctactedeudapagocliente USING(idcentroctactedeudapagocliente,idctactedeudapagocliente)
                              JOIN ctactedeudacliente USING (iddeuda,idcentrodeuda)
                              JOIN informefacturacion ON (idcomprobante = nroinforme*100+idcentroinformefacturacion)
                              JOIN facturaventa USING(nrofactura,tipocomprobante,nrosucursal,tipofactura)
                              JOIN cliente ON  (facturaventa.nrodoc = cliente.nrocliente and facturaventa.barra = cliente.barra)
                              WHERE concat(nroordenpago,'|',idcentroordenpago) =rinfo.idcomprobantesiges;
                              IF FOUND THEN	  
                         		info = info_cliente.lainfo;
			      END IF;   
            
                   END IF;
                   
                  
      END IF;
     /* IF nullvalue(info) THEN    
	       info=concat('ERROR idasientogenericoitem=',rinfo.idasientogenericoitem,' idcentroasientogenericoitem=' ,rinfo.idcentroasientogenericoitem);
	  END IF;*/
RETURN info;
END;
$function$
