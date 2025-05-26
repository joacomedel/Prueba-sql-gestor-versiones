CREATE OR REPLACE FUNCTION public.buscarconsumoafiliadoodonto(character varying, integer, date, date)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$DECLARE
    ref refcursor :='consumoodonto';
BEGIN
    OPEN ref FOR (SELECT  nrodoc,tipodoc ,usunombre,usuapellido,fmiporreintegro,fmifechaauditoria,idprestador,idfichamedica,
	idcentrofichamedica,idcentrofichamedicaitem,idnomenclador,idcapitulo,idsubcapitulo
       ,idpractica,pradescripcion,predescripcion,	nroorden,centro,fmicantidad,fmidescripcion
        ,idpiezadental,idletradental,idzonadental,
	nroreintegro,idcentroregional,posobrepieza,poconducto,posinpieza

       ,poimplanteflotante,pocorona,poperno,idfichamedicaitemodonto, idcentrofichamedicaitemodonto,idfichamedicaitemsico,
	idcentrofichamedicaitemsico,iddiagnostico
        ,prioridad

         FROM 
          (


        SELECT  fichamedica.nrodoc,fichamedica.tipodoc ,nombres as usunombre,apellido as usuapellido,fmiporreintegro,fmifechaauditoria,fichamedicaitem.idprestador,fichamedicaitem.idfichamedica,
	fichamedicaitem.idcentrofichamedica,fichamedicaitem.idcentrofichamedicaitem,fichamedicaitem.idfichamedicaitem,
	fichamedicaitem.idusuario,fichamedicaitem.idnomenclador,fichamedicaitem.idcapitulo,fichamedicaitem.idsubcapitulo,
	fichamedicaitem.idpractica,practica.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	fichamedicaitememisiones.nroorden,fichamedicaitememisiones.centro,fichamedicaitem.fmicantidad,fichamedicaitem.fmidescripcion,
	fichamedicaitemodonto.idpiezadental,fichamedicaitemodonto.idletradental,fichamedicaitemodonto.idzonadental,
	fichamedicaitememisiones.nroreintegro,fichamedicaitememisiones.idcentroregional,posobrepieza,poconducto,posinpieza,
	poimplanteflotante,pocorona,poperno,idfichamedicaitemodonto, idcentrofichamedicaitemodonto,idfichamedicaitemsico,
	idcentrofichamedicaitemsico,iddiagnostico
        , 1 as prioridad


	FROM fichamedica LEFT JOIN fichamedicaitem USING(idfichamedica,idcentrofichamedica)
	LEFT JOIN fichamedicaitemodonto USING(idfichamedicaitem,idcentrofichamedicaitem) 	
	LEFT JOIN fichamedicaitemsico USING(idfichamedicaitem,idcentrofichamedicaitem)    
	LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)     
	LEFT JOIN practicasodontograma USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)     
	LEFT JOIN prestador USING(idprestador)
        LEFT JOIN fichamedicaitememisiones USING(idfichamedicaitem,idcentrofichamedicaitem)     
        JOIN (SELECT dni as nrodoc, tipodoc, idusuario, nombre as nombres, apellido FROM usuario ) as usuario using(idusuario)
	WHERE NOT nullvalue(fichamedicaitememisiones.nroorden) AND fichamedica.nrodoc  = $1 AND fichamedica.tipodoc = $2 AND (idauditoriatipo=1 OR idauditoriatipo=2) AND fmifechaauditoria>=$3 AND fmifechaauditoria <=$4 

/*CON ESTO OBTENGO LO AUDITADO EN EL SECTOR AUDITORIA */
	UNION 
	SELECT fichamedica.nrodoc,fichamedica.tipodoc, nombres as usunombre,apellido as usuapellido,null as fmiporreintegro,fmpafechaingreso,idprestador,idfichamedica,	idcentrofichamedica,null as idcentrofichamedicaitem,fichamedicapreauditada.idfichamedicaitem,fmpaidusuario as idusuario,fichamedicapreauditada.idnomenclador,fichamedicapreauditada.idcapitulo,fichamedicapreauditada.idsubcapitulo,
	fichamedicapreauditada.idpractica,practica.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	parafichamedicapreauditada.nroorden,parafichamedicapreauditada.centro,fichamedicapreauditada.fmpacantidad,
        fichamedicapreauditada.fmpadescripcion,
	fichamedicapreauditadaodonto.idpiezadental,fichamedicapreauditadaodonto.idletradental,fichamedicapreauditadaodonto.idzonadental,
	null as nroreintegro,parafichamedicapreauditada.idcentrofichamedicapreauditada AS idcentroregional,posobrepieza,poconducto,posinpieza,
	poimplanteflotante,pocorona,poperno,NULL AS idfichamedicaitemodonto, null as idcentrofichamedicaitemodonto,null as idfichamedicaitemsico,
	null as idcentrofichamedicaitemsico,null as iddiagnostico
        , 2 as prioridad
        FROM fichamedica JOIN fichamedicapreauditada  USING(idfichamedica,idcentrofichamedica) 	
	JOIN  fichamedicapreauditadaodonto USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
	JOIN parafichamedicapreauditada USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
	LEFT JOIN  ordenesutilizadas USING (nroorden, centro) LEFT JOIN prestador USING(idprestador) 
        LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
	LEFT JOIN practicasodontograma USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
	JOIN (SELECT dni as nrodoc, tipodoc, idusuario as fmpaidusuario, nombre as nombres, apellido FROM usuario ) as usuario USING(fmpaidusuario)

	WHERE nrodocuso  = $1 AND tipodocuso = $2 AND fmpafechaingreso>=$3 AND fmpafechaingreso <=$4 
	UNION
/*CON ESTO OBTENGO LO EXPENDIDO */
	SELECT nrodoc,tipodoc,'Expendido' as usunombre ,'en Expendio ' as usuapellido,null as fmiporreintegro, fechaemision as fmifechaauditoria, idprestador
	,null as idfichamedica	,null as idcentrofichamedica, null as idcentrofichamedicaitem,null as idfichamedicaitem
	,null as idusuario, idnomenclador, idcapitulo,idsubcapitulo,idpractica,practica.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	orden.nroorden,orden.centro,item.cantidad as fmpacantidad,null as fmpadescripcion, idpiezadental,idletradental, idzonadental,
	null as nroreintegro,null as idcentroregional,null as posobrepieza,null as poconducto,null as posinpieza,
	null as poimplanteflotante,null as pocorona,null as poperno,NULL AS idfichamedicaitemodonto, null as idcentrofichamedicaitemodonto,null as idfichamedicaitemsico,
	null as idcentrofichamedicaitemsico,null as iddiagnostico
        , 3 as prioridad
	FROM item  NATURAL JOIN itemvalorizada  LEFT JOIN ordenodonto USING (iditem, centro,nroorden)  NATURAL JOIN  consumo
	NATURAL JOIN ordvalorizada LEFT JOIN matricula USING(nromatricula) LEFT JOIN prestador USING(idprestador)
	NATURAL JOIN orden  NATURAL JOIN persona 
	JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)   
	WHERE practica.idnomenclador='14' AND nrodoc  = $1 AND tipodoc = $2  AND fechaemision>=$3 AND fechaemision <=$4 ) AS T

	JOIN (SELECT nroorden, centro, MIN(prioridad) as prioridad
	FROM(
	SELECT fichamedicaitememisiones.nroorden,fichamedicaitememisiones.centro, 1 as prioridad
	FROM fichamedica LEFT JOIN fichamedicaitem USING(idfichamedica,idcentrofichamedica) 
	LEFT JOIN fichamedicaitememisiones USING(idfichamedicaitem,idcentrofichamedicaitem) 
	WHERE nrodoc  = $1 AND tipodoc = $2 AND (idauditoriatipo=1 OR idauditoriatipo=2) AND fmifechaauditoria>=$3 AND fmifechaauditoria <=$4 
	UNION
	SELECT parafichamedicapreauditada.nroorden,parafichamedicapreauditada.centro  , 2 as prioridad
	FROM  fichamedica JOIN fichamedicapreauditada  USING(idfichamedica,idcentrofichamedica) 
	JOIN  fichamedicapreauditadaodonto USING(idfichamedicapreauditada,idcentrofichamedicapreauditada)	
	JOIN  parafichamedicapreauditada USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
	WHERE nrodoc  = $1 AND tipodoc = $2 AND fmpafechaingreso>=$3 AND fmpafechaingreso <=$4 
	UNION
	SELECT orden.nroorden,orden.centro,3 AS prioridad
	FROM item NATURAL JOIN itemvalorizada NATURAL JOIN  consumo NATURAL JOIN orden
	WHERE idnomenclador='14' AND nrodoc  = $1 AND tipodoc = $2 AND fechaemision>=$3 AND fechaemision <=$4) AS TEMPPRI
	GROUP BY nroorden, centro
	) AS TT USING(nroorden,centro, prioridad)
)
       UNION 

        SELECT  fichamedica.nrodoc,fichamedica.tipodoc ,nombres as usunombre,apellido as usuapellido,fmiporreintegro,fmifechaauditoria,idprestador,idfichamedica,
	idcentrofichamedica,idcentrofichamedicaitem,idnomenclador,idcapitulo,idsubcapitulo
,idpractica,practica.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,	nroorden,centro,fmicantidad,fmidescripcion
,idpiezadental,idletradental,idzonadental,
	nroreintegro,idcentroregional,posobrepieza,poconducto,posinpieza
,poimplanteflotante,pocorona,poperno,idfichamedicaitemodonto, idcentrofichamedicaitemodonto,idfichamedicaitemsico,
	idcentrofichamedicaitemsico,iddiagnostico
        ,1 as prioridad


	FROM fichamedica LEFT JOIN fichamedicaitem USING(idfichamedica,idcentrofichamedica)
	LEFT JOIN fichamedicaitemodonto USING(idfichamedicaitem,idcentrofichamedicaitem) 	
	LEFT JOIN fichamedicaitemsico USING(idfichamedicaitem,idcentrofichamedicaitem)    
	LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)     
	LEFT JOIN practicasodontograma USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)     
	LEFT JOIN prestador USING(idprestador)
        LEFT JOIN fichamedicaitememisiones USING(idfichamedicaitem,idcentrofichamedicaitem)     
        JOIN (SELECT dni as nrodoc, tipodoc, idusuario, nombre as nombres, apellido FROM usuario ) as usuario using(idusuario)
	WHERE nullvalue(fichamedicaitememisiones.nroorden) AND fichamedica.nrodoc  = $1 AND fichamedica.tipodoc = $2 AND (idauditoriatipo=1 OR idauditoriatipo=2) AND fmifechaauditoria>=$3 AND fmifechaauditoria <=$4;


    RETURN ref;
END;$function$
