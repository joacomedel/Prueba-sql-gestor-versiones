CREATE OR REPLACE FUNCTION public.conciliacionbancaria_vincularconciliacionasiento(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	 rfiltros record ;
	 rbusq record;
	 rconc record;
	 eltipocomp varchar;
	 cadbusq varchar;
	 laoperacion varchar;
         tipomov varchar;
BEGIN
 

 EXECUTE sys_dar_filtros($1) INTO rfiltros;
 


 IF (rfiltros.idconciliacionbancaria ) THEN
         -- incorporamos los asientos de las OPC
     
 
         UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (
    	          SELECT idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
    	          FROM (
   	                 SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
    			 'pagoordenpagocontable'::VARCHAR as tablacomp,   		 concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar as clavecomp
       	,idasientogenerico,    idcentroasientogenerico ,agdescripcion
   	   	   	 FROM  pagoordenpagocontable
   	    	   	 NATURAL JOIN ordenpagocontableestado
   	    	   	 NATURAL JOIN ordenpagocontable
   	    	   	 JOIN asientogenerico ON (idasientogenericocomprobtipo=1
     							   AND   concat(idordenpagocontable,'|',idcentroordenpagocontable    ) = idcomprobantesiges
   							   AND nullvalue(idasientogenericorevertido)
        						   AND  agdescripcion not ilike '%REVERSION%' 
     	)
  	 
   	    	   	WHERE	opcfechaingreso>='2022-04-01' AND opcfechaingreso<='2022-04-30'  
   		  	AND ( idordenpagocontableestadotipo <> 6 AND nullvalue(opcfechafin))
    	) as T
    JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
    WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria   and  cbicomsiges ilike '%OPC%'
    
) as A    
WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem ; 
      
    -- incorporamos los asientos de las LT


         UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (

                  SELECT  idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
  FROM  ( SELECT 	  'liquidaciontarjeta'::VARCHAR as tablacomp,
	             concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta)::varchar as clavecomp
		 ,idasientogenerico,	idcentroasientogenerico 
		FROM  liquidaciontarjeta
		NATURAL JOIN cuentabancariasosunc
		NATURAL JOIN liquidaciontarjetaestado
		JOIN mapeoliquidaciontarjeta USING (idliquidaciontarjeta,idcentroliquidaciontarjeta )
                JOIN asientogenerico ON ( idasientogenericocomprobtipo= 4
                                  AND idcomprobantesiges =  concat(nroordenpago,'|',idcentroordenpago )
                                  AND nullvalue(idasientogenericorevertido)
                                  AND agdescripcion not ilike '%REVERSION%' )
		
		WHERE ltfechapago>='2022-01-01'  and ltfechapago<='2022-06-30'
			AND ( idtipoestadoliquidaciontarjeta <> 1 and nullvalue(ltefechafin)) 
             ) as T
   JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
   WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria and  cbicomsiges ilike '%LT%'

) as A    
WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem ;


   --- Recibos

         UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (

                  SELECT  idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
                    FROM  (



                SELECT  concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon)::varchar as clavecomp			
	             ,idasientogenerico,idcentroasientogenerico 
		FROM recibo 
		NATURAL JOIN recibocupon
		LEFT JOIN (select idcomprobante ,idcentropago,nrocliente ,barra,denominacion,idclientectacte,idcentroclientectacte
				   from ctactepagocliente natural join clientectacte natural join cliente
				   union
				   select idcomprobante ,idcentropago,nrodoc as nrocliente ,tipodoc as barra,denominacion,1 as idclientectacte,1 as idcentroclientectacte
				   from cuentacorrientepagos 
				   join cliente on (nrodoc=nrocliente and cliente.barra=cuentacorrientepagos.tipodoc)
		) as datosrecibo ON (idcomprobante = idrecibo and centro = idcentropago )
		
		JOIN asientogenerico ON ( idasientogenericocomprobtipo= 8
                                  AND idcomprobantesiges =  concat(idrecibo,'|',centro )
                                  AND nullvalue(idasientogenericorevertido)
                                  AND agdescripcion not ilike '%REVERSION%' )
		
                  WHERE fecharecibo::date >= '2022-01-01' and fecharecibo::date<='2022-04-30'
			 
			and nullvalue(reanulado)
			 and (not nullvalue (datosrecibo.idcomprobante) )
) as T
	   JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
   WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria and  cbicomsiges ilike '%RE%'

) as A    
WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem ; 
		
  --factura
         UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (

             SELECT  idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
             FROM  (
      

                   SELECT      	concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp
			
		 ,asientogenerico.idasientogenerico,	asientogenerico.idcentroasientogenerico 
		FROM facturaventa 
		NATURAL JOIN facturaventacupon 
                -- LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
		JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
		JOIN asientogenerico  ON ( idasientogenericocomprobtipo= 5 
                           AND idcomprobantesiges =  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura)
                           AND nullvalue(idasientogenericorevertido)
                           AND  agdescripcion not ilike '%REVERSION%' )  
	
	     WHERE fechaemision  >= '2022-01-01' and fechaemision<= '2022-06-30' 
			AND (tipofactura ='FA'  or tipofactura ='DC' or tipofactura ='RC'  or tipofactura ='NC')
			
			AND  nullvalue(anulada) 
			
) as T
	   JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
   WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria and  cbicomsiges ilike '%FA%'

) as A    
WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem ;

--- NC

          UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (

                  SELECT  idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
                  FROM  (    

                 SELECT	concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp 
,idasientogenerico,idcentroasientogenerico 
		FROM facturaventa 
		NATURAL JOIN facturaventacupon 
               	JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
		JOIN asientogenerico  ON ( idasientogenericocomprobtipo= 5 
                           AND idcomprobantesiges =  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura)
                           AND nullvalue(idasientogenericorevertido)
                           AND  agdescripcion not ilike '%REVERSION%' ) 
		WHERE fechaemision  >= '2022-01-01'   and fechaemision<='2022-06-30'
			AND ( tipofactura ='DC' or tipofactura ='RC' or tipofactura ='NC')
			
			AND  nullvalue(anulada) 
			

         ) as T
	   JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
            WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria and  cbicomsiges ilike '%NC%'

) as A    
WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem ;


   ---  Minutas
          UPDATE conciliacionbancariaitem
         SET idasientogenerico =  A.idasientogenerico  , idcentroasientogenerico = A.idcentroasientogenerico
         FROM (
         SELECT  idconciliacionbancariaitem , idcentroconciliacionbancariaitem  ,T.idasientogenerico as idasientogenerico ,      	T.idcentroasientogenerico   as  idcentroasientogenerico
           FROM  (

                  SELECT  concat('nroordenpago=',nroordenpago,'|idcentroordenpago=',idcentroordenpago)::varchar as clavecomp
		     
			 ,idasientogenerico,idcentroasientogenerico 
	       FROM  ordenpago
	       JOIN ordenpagotipo using (idordenpagotipo) 
           NATURAL JOIN ordenpagoimputacion
           NATURAL JOIN cambioestadoordenpago
           JOIN asientogenerico  ON  (idasientogenericocomprobtipo=4  
                  AND nullvalue(idasientogenericorevertido) 
                  AND   concat(nroordenpago,'|',idcentroordenpago) = idcomprobantesiges  
                  AND  agdescripcion not ilike '%REVERSION%'
           ) 

           WHERE (idordenpagotipo <>7 AND idordenpagotipo <> 2 )
		   
			   
		       AND fechaingreso>='2022-01-01' and fechaingreso<='2022-06-30'
		       AND ( nullvalue(ceopfechafin)and idtipoestadoordenpago <>4	) 
		      
			

         ) as T
	   JOIN conciliacionbancariaitem ON(trim(cbiclavecompsiges) = trim(clavecomp) )  
            WHERE idconciliacionbancaria =rfiltros.idconciliacionbancaria  and  cbicomsiges ilike '%MIN%'

     ) as A    
     WHERE conciliacionbancariaitem.idconciliacionbancariaitem = A.idconciliacionbancariaitem
   	AND  conciliacionbancariaitem.idcentroconciliacionbancariaitem =  A.idcentroconciliacionbancariaitem;


  END IF;

  
END
$function$
