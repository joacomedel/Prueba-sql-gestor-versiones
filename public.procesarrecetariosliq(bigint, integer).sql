CREATE OR REPLACE FUNCTION public.procesarrecetariosliq(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--cursor

	creceliq refcursor;
--record
	--existere RECORD;
	unrece RECORD;
	elrecetario RECORD;
        rimpmnroregistro RECORD;
        elnuevorece RECORD;
--VARIABLES
      
/******************select  * from procesarrecetariosliq(206018,2024)**********************************/

BEGIN
    OPEN creceliq FOR
               SELECT CASE WHEN not nullvalue(me.mnroregistro)   THEN me.mnroregistro WHEN not nullvalue(fme.mnroregistro) THEN fme.mnroregistro 
                  ELSE a.idarticulo*10000 + a.idcentroarticulo END as mnroregistro,
                  CASE WHEN nullvalue(me.nomenclado)   THEN FALSE ELSE me.nomenclado END as nomenclado,
                   
                   *,  fovr.idprestador AS idprestadorfovr
                  ,CASE when nullvalue(ovrfechauso) then fov.ovfechaemision ELSE ovrfechauso end as fechauso                       
            	
			   
		FROM far_ordenventa as fov NATURAL JOIN far_ordenventaitem as fovi NATURAL JOIN far_ordenventaitemimportes as fovii 		
		NATURAL JOIN   far_liquidacionitemovii JOIN far_liquidacionitems  USING(idliquidacionitem, idcentroliquidacionitem) 		   
		NATURAL JOIN far_liquidacion  as fl NATURAL JOIN far_articulo as a 
                JOIN reclibrofact AS rlf ON  (rlf.numero =(trim(lpad(fl.idliquidacion, 8, '0'))))
			   
		LEFT JOIN medicamento as me on a.acodigobarra = me.mcodbarra::text
                LEFT JOIN far_medicamento as fme on a.idarticulo = fme.idarticulo AND a.idcentroarticulo = fme.idcentroarticulo
             
		LEFT JOIN far_ordenventareceta AS fovr ON(fovi.idordenventa=fovr.idordenventa AND fovi.idcentroordenventa=fovr.idcentroordenventa) 		   
		LEFT JOIN  far_afiliado USING(idafiliado)   LEFT JOIN persona USING(nrodoc, tipodoc)
		WHERE  rlf.numeroregistro=$1 AND  rlf.anio = $2 
                  ORDER BY idordenventaitemimporte
--LIMIT 100 offset 1500
;    

   FETCH creceliq into unrece;
   WHILE  FOUND LOOP
        
	SELECT INTO elrecetario * FROM recetario 
                       WHERE nrorecetario=unrece.nrorecetario AND centro=unrece.centro;

	IF NOT FOUND THEN
	 
             --si no lo encuentro genero un nuevo recetario 
	     PERFORM generarordenconsultarecetario(unrece.nrodoc, unrece.tipodoc);
	     SELECT INTO elnuevorece * FROM ttordenesgeneradas;
             elrecetario.nrorecetario = elnuevorece.nroorden;
	     elrecetario.centro=elnuevorece.centro;

             UPDATE far_ordenventareceta  SET nrorecetario=elrecetario.nrorecetario, centro=elrecetario.centro
             WHERE idordenventa=unrece.idordenventa AND idcentroordenventa=unrece.idcentroordenventa;
             

	END IF; 

     --si el prestador es nulo en la receta entonces va prestador 7841 (SELLO ILEGIBLE)
	UPDATE recetario SET fechauso =unrece.fechauso,nrodoc = unrece.nrodoc,tipodoc = unrece.tipodoc
                                ,idprestador = CASE WHEN nullvalue(unrece.idprestadorfovr) THEN 7841 ELSE unrece.idprestadorfovr END 		
				,idFarmacia = unrece.idprestador ,nroregistro = unrece.numeroregistro,anio=unrece.anio	 	
				WHERE nrorecetario = elrecetario.nrorecetario  AND centro =elrecetario.centro;

        SELECT INTO rimpmnroregistro * FROM  valormedicamento 
         WHERE mnroregistro=unrece.mnroregistro AND ((vmfechaini::date <= unrece.ovfechaemision AND nullvalue(vmfechafin)) 
               OR (vmfechaini::date <= unrece.ovfechaemision and vmfechafin::date > unrece.ovfechaemision));


        IF NOT  iftableexistsparasp('fichamedicapreauditada_temporal') THEN 
             CREATE TEMP TABLE fichamedicapreauditada_temporal (tipo bigint,descripciondebito VARCHAR,idmotivodebitofacturacion INTEGER,importedebito DOUBLE PRECISION,fmpaiimportes DOUBLE PRECISION,fmpaiimporteiva DOUBLE PRECISION, fmpaiimportetotal DOUBLE PRECISION ,fmpadescripcion VARCHAR,
	idplancobertura INTEGER,fechauso DATE, importe FLOAT, idauditoriatipo INTEGER, idprestador INTEGER, idcentrofichamedicaitemodonto INTEGER,idfichamedicaitemodonto INTEGER, idzonadental VARCHAR, idletradental VARCHAR, idpiezadental VARCHAR, idfichamedicapreauditadaodonto INTEGER, 
	idcentrofichamedicapreauditadaodonto INTEGER, idfichamedicaitem  INTEGER ,     idcentrofichamedicaitem  INTEGER ,     fmpaporeintegro  BOOLEAN DEFAULT false,     idfichamedicapreauditada  BIGINT,idcentrofichamedicapreauditada  INTEGER DEFAULT centro()
	,idauditoriaodontologiacodigo  BIGINT DEFAULT 0,     idnomenclador  VARCHAR,     idcapitulo  VARCHAR,     idsubcapitulo  VARCHAR,     idpractica  VARCHAR,     fmpacantidad  INTEGER,     fmpaidusuario  INTEGER,     fmpafechaingreso  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),     
	idfichamedica  INTEGER,     idcentrofichamedica  INTEGER,      nrodoc VARCHAR,    tipodoc INTEGER,   iditem  BIGINT,     centro  INTEGER,     fmpaifechaingreso  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),    nroregistro  BIGINT,     anio  INTEGER,     nroorden  BIGINT) WITHOUT OIDS;
        ELSE  DELETE FROM fichamedicapreauditada_temporal;
        END IF;


	 IF NOT  iftableexistsparasp('temprecetarioitem') THEN 
            CREATE TEMP TABLE temprecetarioitem (nrorecetario integer NOT NULL,	    centro integer NOT NULL,	    mnroregistro integer NOT NULL,	    nomenclado BOOLEAN NOT NULL,	    idmotivodebito integer,	    importe double precision,	    importeapagar double precision,	    ridebito double precision,	    importevigente double precision,	    coberturaporplan real,	    coberturaefectiva real) WITHOUT OIDS;
        ELSE  DELETE FROM temprecetarioitem;
        END IF;
	
	INSERT INTO temprecetarioitem(nrorecetario, centro, mnroregistro, nomenclado, idmotivodebito, importe, importeapagar, ridebito, importevigente, coberturaporplan, coberturaefectiva ) 
	VALUES (elrecetario.nrorecetario,elrecetario.centro,unrece.mnroregistro,unrece.nomenclado,NULL,unrece.oviimonto,unrece.oviimonto,'0.00',
         rimpmnroregistro.vmimporte,unrece.oviiporcentajecobertura*100,unrece.oviiporcentajecobertura*100);

	INSERT INTO fichamedicapreauditada_temporal(idfichamedicaitem ,idcentrofichamedicaitem ,fmpaporeintegro,idfichamedicapreauditada,
        idcentrofichamedicapreauditada,idauditoriaodontologiacodigo,idnomenclador,idcapitulo, idsubcapitulo,idpractica,fmpacantidad,
        fmpaidusuario,fmpafechaingreso,iditem,centro,nroregistro,anio,idfichamedicapreauditadaodonto,idcentrofichamedicapreauditadaodonto,
        idpiezadental,idletradental,idzonadental,idfichamedicaitemodonto,idcentrofichamedicaitemodonto,nroorden,nrodoc,tipodoc,
        idprestador,idauditoriatipo,fechauso,importe,idplancobertura,fmpadescripcion,fmpaifechaingreso,fmpaiimportes,fmpaiimporteiva
        ,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo)
         VALUES (NULL,NULL,FALSE,null,1,0,'98','01','01','01',unrece.ovicantidad,/*unrece.idusuario*/25,now(),unrece.mnroregistro,elrecetario.centro,unrece.numeroregistro,unrece.anio,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,elrecetario.nrorecetario,unrece.nrodoc,unrece.tipodoc,unrece.idprestadorfovr,3,unrece.fechauso, unrece.oviimonto,1,NULL,now(),
             unrece.oviimonto,NULL,unrece.oviimonto,NULL,'0.00',NULL,14);
	 PERFORM alta_modifica_preauditoria_odonto();
	
        FETCH creceliq into unrece;
        END LOOP;
       CLOSE creceliq;


      INSERT INTO ordenreciprocidadpreauditada (nroorden,anio,nroregistro,centro,idcomprobantetipos,barra,idosreci)
     SELECT DISTINCT recitemporal.nroorden, recitemporal.anio, recitemporal.nroregistro,recitemporal.centro , tipo,AA.barra,AA.idosreci 
	FROM (SELECT P.nrodoc, P.tipodoc,P.nroorden, P.centro, ordenesutilizadas.tipo, nroregistro, anio,nroordenpago,fechauso 
	      FROM factura  JOIN facturaordenesutilizadas USING(nroregistro, anio) 
	     JOIN ordenesutilizadas USING(nroorden, centro,tipo) 
            
             JOIN 
	     (SELECT fichamedica.nrodoc, fichamedica.tipodoc,T.nroorden, T.centro, tipo 
	     FROM  fichamedica JOIN fichamedicapreauditada USING(idfichamedica, idcentrofichamedica) 
	     JOIN  (SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
		FROM  fichamedicapreauditadaitemconsulta 
		UNION 
               SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
	       FROM fichamedicapreauditadaitem NATURAL JOIN itemvalorizada ) as T 
	       USING(idfichamedicapreauditada, idcentrofichamedicapreauditada) ) AS P USING(nroorden,centro,tipo) 
		UNION 
	    SELECT r.nrodoc, r.tipodoc, r.nrorecetario as nroorden, r.centro, CASE WHEN nullvalue(rtp.nrorecetario) THEN 14 ELSE 37 END as tipo
		,nroregistro, anio, nroordenpago ,fechauso 
		FROM factura JOIN recetario as r USING(nroregistro,anio) LEFT JOIN recetariotp as rtp  ON(r.nrorecetario=rtp.nrorecetario 
                  AND r.centro=rtp.centro) ) AS recitemporal 	NATURAL JOIN persona JOIN 
		   ( SELECT osreci.barra,descrip,idosreci, nrodoc, tipodoc, abreviatura FROM osreci JOIN afilreci USING(idosreci,barra)
		      UNION 
		    SELECT osreci.barra,descrip,idosreci, benefreci.nrodoc, benefreci.tipodoc, abreviatura 
		     FROM osreci  JOIN afilreci  USING(idosreci,barra) 
		    JOIN benefreci ON (nrodoctitu = afilreci.nrodoc AND tipodoctitu = afilreci.tipodoc) ) AS AA USING(nrodoc, tipodoc) 
                     JOIN histobarras USING(nrodoc, tipodoc)
LEFT JOIN ordenreciprocidadpreauditada as orp ON (recitemporal.nroorden = orp.nroorden AND recitemporal.centro=orp.centro AND recitemporal.tipo=orp.idcomprobantetipos)
		WHERE recitemporal.nroregistro=$1 AND  recitemporal.anio = $2 AND (cast(histobarras.fechaini as date)<= fechauso)  AND nullvalue(orp.nroorden)
               AND (cast(histobarras.fechafin as date)>= fechauso) AND histobarras.barra>=100;	 
		    	
return 	true;
END;
$function$
