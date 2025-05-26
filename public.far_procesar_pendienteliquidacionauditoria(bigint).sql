CREATE OR REPLACE FUNCTION public.far_procesar_pendienteliquidacionauditoria(bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--record
	
    unrece RECORD;
    rimpmnroregistro RECORD;
    elnuevorece RECORD;
    rlaficha RECORD;
    rreauditado RECORD;
    auxprestador RECORD;
--VARIABLES
    lacantidad INTEGER;  
    fmpamonto DOUBLE PRECISION;
    elnuevoprestador BIGINT;
BEGIN
    
	SELECT INTO unrece 
	CASE WHEN not nullvalue(me.mnroregistro)   THEN me.mnroregistro WHEN not nullvalue(fme.mnroregistro) THEN fme.mnroregistro 
        ELSE a.idarticulo*10000 + a.idcentroarticulo END as mnroregistro,ovla.nroregistro as numeroregistro,
        CASE WHEN nullvalue(me.nomenclado)   THEN FALSE ELSE me.nomenclado END as nomenclado,
        (trim(lpad(far_afiliado.nrodoc, 8, '0'))) as nrodoc,
        *, CASE WHEN nullvalue(fovr.idprestador)  THEN 7841 ELSE fovr.idprestador END AS idprestadorfovr, ovla.nrorecetario as nrorecetarioovla
        ,CASE when nullvalue(ovrfechauso) then fov.ovfechaemision ELSE ovrfechauso end as fechauso  ,laorden.nroorden as datoorden                    
	FROM far_ordenventaliquidacionauditada AS ovla NATURAL JOIN far_ordenventa as fov NATURAL JOIN far_ordenventaitem as fovi NATURAL JOIN far_ordenventaitemimportes as fovii 	NATURAL JOIN far_articulo as a 
	LEFT JOIN far_ordenventareceta AS fovr ON(fovi.idordenventa=fovr.idordenventa AND fovi.idcentroordenventa=fovr.idcentroordenventa) 	
LEFT JOIN orden as laorden ON(ovla.nrorecetario=laorden.nroorden  AND ovla.centro=laorden.centro) 	

        LEFT JOIN medicamento as me on a.acodigobarra = me.mcodbarra::text
        LEFT JOIN far_medicamento as fme on a.idarticulo = fme.idarticulo AND a.idcentroarticulo = fme.idcentroarticulo
        LEFT JOIN  far_afiliado USING(idafiliado)   LEFT JOIN persona USING(nrodoc, tipodoc)
	WHERE  ovla.idordenventaliquidacionauditada=$1 and not nullvalue(persona.nrodoc);    

   IF FOUND THEN
        
	IF (nullvalue(unrece.nrorecetarioovla) or  trim(unrece.nrorecetarioovla)=''  or nullvalue(unrece.datoorden)) THEN 
        --si no lo encuentro genero un nuevo recetario 
		PERFORM generarordenconsultarecetario(unrece.nrodoc, unrece.tipodoc);
	        SELECT INTO elnuevorece * FROM ttordenesgeneradas;
		unrece.nrorecetario = elnuevorece.nroorden;
		unrece.centro=elnuevorece.centro;

		UPDATE far_ordenventareceta  SET nrorecetario=unrece.nrorecetario, centro=unrece.centro
		WHERE idordenventa=unrece.idordenventa AND idcentroordenventa=unrece.idcentroordenventa;

                 UPDATE far_ordenventaliquidacionauditada  
			SET nrorecetario=unrece.nrorecetario, centro=unrece.centro
                         ,ovlagenerarecetario= false
		WHERE idordenventaliquidacionauditada IN (
                            SELECT idordenventaliquidacionauditada 
                            FROM far_ordenventaliquidacionauditada 
                            NATURAL JOIN far_ordenventaitem
                            WHERE idordenventa=unrece.idordenventa AND idcentroordenventa=unrece.idcentroordenventa
                             );
        ELSE 
            SELECT INTO rreauditado * FROM facturaordenesutilizadas 
              WHERE nroorden=unrece.nrorecetarioovla AND centro=unrece.centro AND tipo=14
              AND nroregistro<> unrece.nroregistro;
            IF FOUND THEN /*El recetario ya se audito, genero uno nuevo*/
                 		PERFORM generarordenconsultarecetario(unrece.nrodoc, unrece.tipodoc);
	        SELECT INTO elnuevorece * FROM ttordenesgeneradas;
		unrece.nrorecetario = elnuevorece.nroorden;
		unrece.centro=elnuevorece.centro;

		UPDATE far_ordenventareceta  SET nrorecetario=unrece.nrorecetario, centro=unrece.centro
		WHERE idordenventa=unrece.idordenventa AND idcentroordenventa=unrece.idcentroordenventa;

                 UPDATE far_ordenventaliquidacionauditada  
			SET nrorecetario=unrece.nrorecetario, centro=unrece.centro,
			 nrorecetarioauditado=rreauditado.nroorden,
			 centroauditado=rreauditado.centro
                         ,ovlagenerarecetario= false
		WHERE idordenventaliquidacionauditada IN (
                            SELECT idordenventaliquidacionauditada 
                            FROM far_ordenventaliquidacionauditada 
                            NATURAL JOIN far_ordenventaitem
                            WHERE idordenventa=unrece.idordenventa AND idcentroordenventa=unrece.idcentroordenventa
                             );
            END IF;
        

	END IF; 
    /*Dani agrego 13042023 Si el prestador es de ISSN, no lo tengo en la tabla prestador asi que lo dejo nulo*/
             select into auxprestador * from prestador  where idprestador = unrece.idprestadorfovr;
     if not found then 
            RAISE NOTICE '>>>>>>>>entro por el if not found del prestador (%)', unrece.idprestadorfovr;
           
                  elnuevoprestador=null;
     else
                 elnuevoprestador=unrece.idprestadorfovr;
              RAISE NOTICE '>>>>>>>>entro por el if   found del prestador (%)', unrece.idprestadorfovr;
     end if;
     --si el prestador es nulo en la receta entonces va prestador 7841 (SELLO ILEGIBLE)
     --si farmacia nula entonces idfarmacia es sosunc
	UPDATE recetario SET fechauso =unrece.fechauso,nrodoc = unrece.nrodoc,tipodoc = unrece.tipodoc
                                ,idprestador = /*unrece.idprestadorfovr		*/elnuevoprestador
				,idfarmacia =2219,nroregistro = unrece.numeroregistro,anio=unrece.anio	 	
				WHERE nrorecetario = unrece.nrorecetario  AND centro =unrece.centro;

        SELECT INTO rimpmnroregistro * 
	FROM  valormedicamento 
        WHERE mnroregistro=unrece.mnroregistro AND ((vmfechaini::date <= unrece.ovfechaemision AND nullvalue(vmfechafin)) 
         OR (vmfechaini::date <= unrece.ovfechaemision and vmfechafin::date > unrece.ovfechaemision));


        IF NOT  iftableexists('fichamedicapreauditada_temporal') THEN 
		CREATE TEMP TABLE fichamedicapreauditada_temporal (tipo bigint,descripciondebito VARCHAR,idmotivodebitofacturacion INTEGER,importedebito DOUBLE PRECISION,fmpaiimportes DOUBLE PRECISION,fmpaiimporteiva DOUBLE PRECISION, fmpaiimportetotal DOUBLE PRECISION ,fmpadescripcion VARCHAR,
		idplancobertura INTEGER,fechauso DATE, importe FLOAT, idauditoriatipo INTEGER, idprestador INTEGER, idcentrofichamedicaitemodonto INTEGER,idfichamedicaitemodonto INTEGER, idzonadental VARCHAR, idletradental VARCHAR, idpiezadental VARCHAR, idfichamedicapreauditadaodonto INTEGER, 
		idcentrofichamedicapreauditadaodonto INTEGER, idfichamedicaitem  INTEGER ,     idcentrofichamedicaitem  INTEGER ,     fmpaporeintegro  BOOLEAN DEFAULT false,     idfichamedicapreauditada  BIGINT,idcentrofichamedicapreauditada  INTEGER DEFAULT centro()
		,idauditoriaodontologiacodigo  BIGINT DEFAULT 0,     idnomenclador  VARCHAR,     idcapitulo  VARCHAR,     idsubcapitulo  VARCHAR,     idpractica  VARCHAR,     fmpacantidad  INTEGER,     fmpaidusuario  INTEGER,     fmpafechaingreso  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),     
		idfichamedica  INTEGER,     idcentrofichamedica  INTEGER,      nrodoc VARCHAR,    tipodoc INTEGER,   iditem  BIGINT,     centro  INTEGER,     fmpaifechaingreso  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),    nroregistro  BIGINT,     anio  INTEGER,     nroorden  BIGINT) WITHOUT OIDS;
        ELSE  
		DELETE FROM fichamedicapreauditada_temporal;
        END IF;


	IF NOT  iftableexists('temprecetarioitem') THEN 
		CREATE TEMP TABLE temprecetarioitem (nrorecetario integer NOT NULL,	    centro integer NOT NULL,	    mnroregistro integer NOT NULL,	    nomenclado BOOLEAN NOT NULL,	    idmotivodebito integer,	    importe double precision,	    importeapagar double precision,	    ridebito double precision,	    importevigente double precision,	    coberturaporplan real,	    coberturaefectiva real) WITHOUT OIDS;
        ELSE  
		DELETE FROM temprecetarioitem;
        END IF;

	SELECT INTO rlaficha *
		FROM 	(SELECT * FROM obtenerdatosfichamedicaauditada(unrece.nrorecetarioovla,unrece.centro,
			null ,'A','A',null)		
			WHERE  tipo <> 4 AND tipo<>53	) AS T 
			LEFT JOIN recetarioitem AS ri 
			ON(iditem =idrecetarioitem AND  T.centro=ri.centro AND T.nroorden= ri.nrorecetario ) 		 		
			LEFT JOIN medicamento as m ON(ri.mnroregistro=m.mnroregistro)
                        WHERE ri.mnroregistro= unrece.mnroregistro;

       
        lacantidad= unrece.ovicantidad +(case when nullvalue(rlaficha.cantidad) then 0 else rlaficha.cantidad end);
        fmpamonto = unrece.oviimonto + (case when nullvalue(rlaficha.fmpaiimportes) then 0 else rlaficha.fmpaiimportes end);

           
	INSERT INTO temprecetarioitem(nrorecetario, centro, mnroregistro, nomenclado, 
			idmotivodebito, importe, importeapagar, ridebito, importevigente, 
			coberturaporplan, coberturaefectiva ) 
	VALUES (unrece.nrorecetario,unrece.centro,unrece.mnroregistro,unrece.nomenclado,
                       NULL,fmpamonto,
                       fmpamonto,'0.00',rimpmnroregistro.vmimporte
                       ,unrece.oviiporcentajecobertura*100,unrece.oviiporcentajecobertura*100
			);

	INSERT INTO fichamedicapreauditada_temporal(idfichamedicaitem ,idcentrofichamedicaitem ,fmpaporeintegro,idfichamedicapreauditada,
        idcentrofichamedicapreauditada,idauditoriaodontologiacodigo,idnomenclador,idcapitulo, idsubcapitulo,idpractica,fmpacantidad,        fmpaidusuario,fmpafechaingreso,iditem,centro,nroregistro,anio,idfichamedicapreauditadaodonto,idcentrofichamedicapreauditadaodonto,
        idpiezadental,idletradental,idzonadental,idfichamedicaitemodonto,idcentrofichamedicaitemodonto,nroorden,nrodoc,tipodoc,
        idprestador,idauditoriatipo,fechauso,importe,idplancobertura,fmpadescripcion,fmpaifechaingreso,fmpaiimportes,fmpaiimporteiva
        ,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo)
        VALUES (NULL,NULL,FALSE,rlaficha.idfichamedicapreauditada,1,0,'98','01','01','01',
        lacantidad,/*unrece.idusuario*/25,now(),unrece.mnroregistro,unrece.centro,unrece.numeroregistro,
         unrece.anio,NULL,NULL,NULL,NULL,NULL,NULL,NULL,unrece.nrorecetario,unrece.nrodoc,unrece.tipodoc,2219,3,unrece.fechauso, fmpamonto,1,NULL,now(),
        fmpamonto,NULL,fmpamonto,NULL,'0.00',NULL,14);
	PERFORM alta_modifica_preauditoria_odonto();
	

          UPDATE far_ordenventaliquidacionauditada  SET  	ovlaprocesado= true WHERE idordenventaliquidacionauditada=$1;

        
        END IF;


              
return 	true;
END;$function$
