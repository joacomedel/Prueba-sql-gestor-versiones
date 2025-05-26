CREATE OR REPLACE FUNCTION public.conciliacionbancaria_control(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	 
	 rfiltros record ;
	 rcomprobante record;
	 expcion_descrip varchar;
         rasiento record;
         
      
BEGIN




	-- recupero los parametros '{idasientogenerico=',xidasiento, 'idcentroasientogenerico=',xidcentro,'}'
   	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
	 
         -- busco la info del asiento
         SELECT INTO rasiento * 
         FROM asientogenerico
         WHERE idasientogenerico=rfiltros.idasientogenerico  and idcentroasientogenerico= rfiltros.idcentroasientogenerico;
       



	 expcion_descrip='';
        
	IF (rasiento.idasientogenericocomprobtipo  = 1  ) THEN 	 -- ordenpagocontable

          
   
		SELECT INTO rcomprobante * 
		FROM ordenpagocontable
		NATURAL JOIN pagoordenpagocontable
		JOIN conciliacionbancariaitem ON (cbiactivo and cbiclavecompsiges = concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)  )

		WHERE  idordenpagocontable = split_part(rasiento.idcomprobantesiges , '|', 1)
		      AND idcentroordenpagocontable = split_part(rasiento.idcomprobantesiges , '|', 2);
   	        IF FOUND THEN
			expcion_descrip = concat(' Mov. CONCILIADO ( ',rcomprobante.idconciliacionbancaria,'|' ,rcomprobante.idcentroconciliacionbancaria,' ) ' ,rcomprobante.cbicomsiges); 
			
                END IF;  

	END IF;

    IF (rasiento.idasientogenericocomprobtipo = 2  ) THEN  --Liquidacion tarjeta
		SELECT INTO rcomprobante * 			
		FROM  liquidaciontarjeta
		JOIN conciliacionbancariaitem ON (cbiactivo and  cbiclavecompsiges = concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta) )
		WHERE   idliquidaciontarjeta =split_part(rasiento.idcomprobantesiges , '|', 1)
                        and idcentroliquidaciontarjeta = split_part(rasiento.idcomprobantesiges , '|', 2);

		 IF FOUND THEN
			expcion_descrip = concat(' Mov. CONCILIADO ( ',rcomprobante.idconciliacionbancaria,'|' ,rcomprobante.idcentroconciliacionbancaria,' ) ',rcomprobante.cbicomsiges); 
			
                END IF;  

  END IF;
  

  IF (rasiento.idasientogenericocomprobtipo = 8 ) THEN 
		SELECT INTO rcomprobante * 	
		FROM recibo 
		NATURAL JOIN recibocupon
		JOIN conciliacionbancariaitem ON (cbiactivo and  cbiclavecompsiges =concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon))
		WHERE idrecibo = split_part(rasiento.idcomprobantesiges , '|',1)  AND centro=split_part(rasiento.idcomprobantesiges , '|', 2) ;
                IF FOUND THEN
			expcion_descrip = concat(' Mov. CONCILIADO ( ',rcomprobante.idconciliacionbancaria,'|' ,rcomprobante.idcentroconciliacionbancaria,' ) ' ,rcomprobante.cbicomsiges); 
			
                END IF;  

 
  END IF;

  
  
     IF (rasiento.idasientogenericocomprobtipo = 5  ) THEN
		SELECT INTO rcomprobante *
                FROM facturaventa 
		NATURAL JOIN facturaventacupon 
                JOIN conciliacionbancariaitem ON (cbiactivo and  cbiclavecompsiges = concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura))  
		WHERE nrofactura = split_part(rasiento.idcomprobantesiges, '|', 4)::bigint
		      and tipocomprobante =trim(split_part(rasiento.idcomprobantesiges, '|', 2))::integer
		      and nrosucursal =  split_part(rasiento.idcomprobantesiges, '|', 3)::integer
		      and tipofactura = split_part(rasiento.idcomprobantesiges, '|', 1) ;

                 IF FOUND THEN
			expcion_descrip = concat(' Mov. CONCILIADO( ',rcomprobante.idconciliacionbancaria,'|' ,rcomprobante.idcentroconciliacionbancaria,' ) ' ,rcomprobante.cbicomsiges); 
			
                END IF;  

 
	END IF;

	IF (rasiento.idasientogenericocomprobtipo = 4  ) THEN
		SELECT INTO rcomprobante *			
	        FROM  ordenpago
                JOIN conciliacionbancariaitem ON (cbiactivo and  cbiclavecompsiges = concat('nroordenpago=',nroordenpago,'|idcentroordenpago=',idcentroordenpago)  )
	        WHERE nroordenpago =  split_part(rasiento.idcomprobantesiges, '|', 1)   AND idcentroordenpago = split_part(rasiento.idcomprobantesiges, '|', 2)  ;

                IF FOUND THEN
			expcion_descrip = concat(' Mov. CONCILIADO( ',rcomprobante.idconciliacionbancaria,'|' ,rcomprobante.idcentroconciliacionbancaria,' ) ' ,rcomprobante.cbicomsiges); 
			
                END IF;  
	END IF;
 return expcion_descrip;
 
     
END;
$function$
