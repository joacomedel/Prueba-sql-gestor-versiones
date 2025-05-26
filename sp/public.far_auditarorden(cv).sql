CREATE OR REPLACE FUNCTION public.far_auditarorden(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--record
	
    rfiltros RECORD;
    rordenau RECORD;
    elnuevorece  RECORD;
    rimpmnroregistro  RECORD; 
    rlaficha  RECORD;
--VARIABLES
    lacantidad INTEGER;  
    fmpamonto DOUBLE PRECISION;
    vidusuario bigint;
BEGIN
--far_generapendienteliquidacionauditoria    
 
 EXECUTE sys_dar_filtros($1) INTO rfiltros;  
 vidusuario = sys_dar_usuarioactual();
 SELECT INTO rordenau 
	CASE WHEN not nullvalue(me.mnroregistro)   THEN me.mnroregistro WHEN not nullvalue(fme.mnroregistro) THEN fme.mnroregistro 
        ELSE a.idarticulo*10000 + a.idcentroarticulo END as mnroregistro, 
        CASE WHEN nullvalue(me.nomenclado)   THEN FALSE ELSE me.nomenclado END as nomenclado,
        (trim(lpad(far_afiliado.nrodoc, 8, '0'))) as nrodoc,laorden.nroorden as datoorden                    
	FROM far_ordenventa as fov NATURAL JOIN far_ordenventaitem as fovi NATURAL JOIN far_ordenventaitemimportes as fovii 	NATURAL JOIN far_articulo as a 
	LEFT JOIN medicamento as me on a.acodigobarra = me.mcodbarra::text
        LEFT JOIN far_medicamento as fme on a.idarticulo = fme.idarticulo AND a.idcentroarticulo = fme.idcentroarticulo
        LEFT JOIN  far_afiliado USING(idafiliado)   LEFT JOIN persona USING(nrodoc, tipodoc)
	WHERE  fov.idordenventa = rfiltros.idordenventa  and fov.idcentroordenventa = rfiltros.idcentroordenventa;

   IF FOUND THEN
        
	   -- genero un nuevo recetario 
		PERFORM generarordenconsultarecetario(rordenau.nrodoc, rordenau.tipodoc);
	        SELECT INTO elnuevorece * FROM ttordenesgeneradas;
	
		UPDATE far_ordenventareceta  SET nrorecetario=elnuevorece.nroorden, centro=elnuevorece.centro
		WHERE idordenventa=rfiltros.idordenventa AND idcentroordenventa=rfiltros.idcentroordenventa;

                 UPDATE far_ordenventaliquidacionauditada  
			SET nrorecetario=elnuevorece.nroorden, centro=elnuevorece.centro
                         ,ovlagenerarecetario= false
		WHERE idordenventaliquidacionauditada IN (
                            SELECT idordenventaliquidacionauditada 
                            FROM far_ordenventaliquidacionauditada 
                            NATURAL JOIN far_ordenventaitem
                            WHERE idordenventa=rfiltros.idordenventa AND idcentroordenventa=rfiltros.idcentroordenventa
                             );

          

	 

     --si el prestador es nulo en la receta entonces va prestador 7841 (SELLO ILEGIBLE)
     --si farmacia nula entonces idfarmacia es sosunc
	UPDATE recetario SET fechauso =now(),nrodoc = rordenau.nrodoc,tipodoc = rordenau.tipodoc
                                ,idprestador = rordenau.idprestadorfovr		
				,idfarmacia =2219  	
				WHERE nrorecetario = elnuevorece.nrorecetario  AND centro =elnuevorece.centro;

        SELECT INTO rimpmnroregistro * 
	FROM  valormedicamento 
        WHERE mnroregistro=rordenau.mnroregistro AND ((vmfechaini::date <= rordenau.ovfechaemision AND nullvalue(vmfechafin)) 
         OR (vmfechaini::date <= rordenau.ovfechaemision and vmfechafin::date > rordenau.ovfechaemision));

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
		FROM 	(SELECT * FROM obtenerdatosfichamedicaauditada(rordenau.nrorecetarioovla,rordenau.centro,
			null ,'A','A',null)		
			WHERE  tipo <> 4 AND tipo<>53	) AS T 
			LEFT JOIN recetarioitem AS ri 
			ON(iditem =idrecetarioitem AND  T.centro=ri.centro AND T.nroorden= ri.nrorecetario ) 		 		
			LEFT JOIN medicamento as m ON(ri.mnroregistro=m.mnroregistro)
                        WHERE ri.mnroregistro= rordenau.mnroregistro;

       
        lacantidad= rordenau.ovicantidad +(case when nullvalue(rlaficha.cantidad) then 0 else rlaficha.cantidad end);
        fmpamonto = rordenau.oviimonto + (case when nullvalue(rlaficha.fmpaiimportes) then 0 else rlaficha.fmpaiimportes end);

           
	INSERT INTO temprecetarioitem(nrorecetario, centro, mnroregistro, nomenclado, 
			idmotivodebito, importe, importeapagar, ridebito, importevigente, 
			coberturaporplan, coberturaefectiva ) 
	VALUES (rfiltros.nrorecetario,rordenau.centro,rordenau.mnroregistro,rordenau.nomenclado,
                       NULL,fmpamonto,
                       fmpamonto,'0.00',rimpmnroregistro.vmimporte
                       ,rordenau.oviiporcentajecobertura*100,rordenau.oviiporcentajecobertura*100
			);

	INSERT INTO fichamedicapreauditada_temporal(idfichamedicaitem ,idcentrofichamedicaitem ,fmpaporeintegro,idfichamedicapreauditada,
        idcentrofichamedicapreauditada,idauditoriaodontologiacodigo,idnomenclador,idcapitulo, idsubcapitulo,idpractica,fmpacantidad,        fmpaidusuario,fmpafechaingreso,iditem,centro,nroregistro,anio,idfichamedicapreauditadaodonto,idcentrofichamedicapreauditadaodonto,
        idpiezadental,idletradental,idzonadental,idfichamedicaitemodonto,idcentrofichamedicaitemodonto,nroorden,nrodoc,tipodoc,
        idprestador,idauditoriatipo,fechauso,importe,idplancobertura,fmpadescripcion,fmpaifechaingreso,fmpaiimportes,fmpaiimporteiva
        ,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo)
        VALUES (NULL,NULL,FALSE,rlaficha.idfichamedicapreauditada,1,0,'98','01','01','01',
        lacantidad,vidusuario,now(),rordenau.mnroregistro,rordenau.centro,rordenau.numeroregistro,
         rordenau.anio,NULL,NULL,NULL,NULL,NULL,NULL,NULL,rordenau.nrorecetario,rordenau.nrodoc,rordenau.tipodoc,2219,3,rordenau.fechauso, fmpamonto,1,NULL,now(),
        fmpamonto,NULL,fmpamonto,NULL,'0.00',NULL,14);
	PERFORM alta_modifica_preauditoria_odonto();
	

          UPDATE far_ordenventaliquidacionauditada  SET  	ovlaprocesado= true WHERE idordenventaliquidacionauditada=$1;

        
        END IF;

              
return 	'';
END;
$function$
