CREATE OR REPLACE FUNCTION public.buscarconsumoafiliadoodontov2(character varying, integer, date, date)
 RETURNS SETOF consumoodonto
 LANGUAGE plpgsql
AS $function$DECLARE

	rconsumo consumoodonto;
begin


for rconsumo in 

(SELECT  nrodoc,tipodoc ,usunombre,usuapellido,fmiporreintegro,fmifechaauditoria,idprestador,idfichamedica,
	idcentrofichamedica,idfichamedicaitem,idcentrofichamedicaitem,idnomenclador,idcapitulo,idsubcapitulo
        ,idpractica,pradescripcion,predescripcion,	nroorden,centro,fmicantidad,fmidescripcion
        ,idpiezadental,idletradental,idzonadental
	,nroreintegro,idcentroregional
        ,posobrepieza,poconducto,posinpieza,poimplanteflotante,pocorona,poperno,poarriba,poincrustacion
       ,idfichamedicaitemodonto, idcentrofichamedicaitemodonto,idfichamedicaitemsico,
	idcentrofichamedicaitemsico,iddiagnostico
        ,prioridad

         FROM 
          ( --Malapi 18-02-2015 Modifico para que tome solo una configuracion de odonto, segun la prioridad de la practica
        SELECT  fichamedica.nrodoc,fichamedica.tipodoc ,nombres as usunombre,apellido as usuapellido,fmiporreintegro,fechaemision as fmifechaauditoria,fichamedicaitem.idprestador,fichamedicaitem.idfichamedica,
	fichamedicaitem.idcentrofichamedica,fichamedicaitem.idcentrofichamedicaitem,fichamedicaitem.idfichamedicaitem,
	fichamedicaitem.idusuario,fichamedicaitem.idnomenclador,fichamedicaitem.idcapitulo,fichamedicaitem.idsubcapitulo,
	fichamedicaitem.idpractica,fmipr.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	fichamedicaitememisiones.nroorden,fichamedicaitememisiones.centro,fichamedicaitem.fmicantidad,fichamedicaitem.fmidescripcion
	,fichamedicaitemodonto.idpiezadental,fichamedicaitemodonto.idletradental,fichamedicaitemodonto.idzonadental
	,fichamedicaitememisiones.nroreintegro,fichamedicaitememisiones.idcentroregional
        ,posobrepieza,poconducto,posinpieza,poimplanteflotante,pocorona,poperno,poarriba,poincrustacion
        ,idfichamedicaitemodonto, idcentrofichamedicaitemodonto,idfichamedicaitemsico,
	idcentrofichamedicaitemsico,iddiagnostico
        , 1 as prioridad
	FROM fichamedica 
        LEFT JOIN fichamedicaitem USING(idfichamedica,idcentrofichamedica)
        LEFT JOIN (SELECT max(prioridadconfodonto) as prioridadconfodonto,fmicantidad as cantidad, idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion,idfichamedicaitem, idcentrofichamedicaitem 
                FROM fichamedicaitem
                NATURAL JOIN fichamedica     
                NATURAL JOIN practicasodontograma 
                WHERE idnomenclador='14' AND nrodoc  = $1 AND tipodoc =$2
               GROUP BY idfichamedicaitem, idcentrofichamedicaitem,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion
           )  as fmipr USING(idfichamedicaitem,idcentrofichamedicaitem)
        LEFT JOIN practicasodontograma  as po ON (po.idnomenclador = fmipr.idnomenclador AND  po.idcapitulo = fmipr.idcapitulo AND po.idsubcapitulo = fmipr.idsubcapitulo AND po.idpractica = fmipr.idpractica AND po.prioridadconfodonto = fmipr.prioridadconfodonto)
        LEFT JOIN fichamedicaitemodonto USING(idfichamedicaitem,idcentrofichamedicaitem) 	
	LEFT JOIN fichamedicaitemsico USING(idfichamedicaitem,idcentrofichamedicaitem)    
	LEFT JOIN prestador USING(idprestador)
        LEFT JOIN fichamedicaitememisiones USING(idfichamedicaitem,idcentrofichamedicaitem) 
        LEFT JOIN orden USING (nroorden, centro)      
        JOIN (SELECT dni as nrodoc, tipodoc, idusuario, nombre as nombres, apellido FROM usuario ) as usuario using(idusuario)
	WHERE /*NOT nullvalue(fichamedicaitememisiones.nroorden) AND*/ fichamedica.nrodoc  = $1 AND fichamedica.tipodoc = $2 AND (idauditoriatipo=1 OR idauditoriatipo=2) AND fmifechaauditoria>=$3 AND fmifechaauditoria <=$4 
/* KR 25-09-18 ELIMINO UNION ya que ahora al momento de expenderse la orden se guarda la información en el item de la ficha. 

	UNION
/*CON ESTO OBTENGO LO EXPENDIDO Modifica Malapi 23-09-2014 para que tome una sola configuracion de practicaodonto*/
	 SELECT DISTINCT nrodoc,tipodoc,'Expendido' as usunombre ,'en Expendio ' as usuapellido,false as fmiporreintegro, fechaemision as fmifechaauditoria, idprestador
	,null::integer as idfichamedica	,null::integer as idcentrofichamedica, null::integer as idcentrofichamedicaitem,null::integer as idfichamedicaitem
	,null::integer as idusuario, idnomenclador, idcapitulo,idsubcapitulo,idpractica,po.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	orden.nroorden,orden.centro,item.cantidad as fmpacantidad,null as fmpadescripcion
       , idpiezadental,idletradental, idzonadental
	,null::integer as nroreintegro,null::integer as idcentroregional
       ,posobrepieza,poconducto,posinpieza,poimplanteflotante,pocorona,poperno,poarriba,poincrustacion
       ,NULL::integer AS idfichamedicaitemodonto, null::integer as idcentrofichamedicaitemodonto,null::integer as idfichamedicaitemsico,
	null::integer as idcentrofichamedicaitemsico,null as iddiagnostico
        , 3 as prioridad
	FROM (SELECT max(prioridadconfodonto) as prioridadconfodonto,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion,iditem, centro
                FROM item  
                NATURAL JOIN itemvalorizada
                NATURAL JOIN ordvalorizada 
                NATURAL JOIN practicasodontograma 
                NATURAL JOIN consumo  
               WHERE idnomenclador='14' AND nrodoc  = $1 AND tipodoc = $2 AND not anulado
               GROUP BY iditem, centro,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion
           ) as  item
        NATURAL JOIN practicasodontograma  as po
        NATURAL JOIN itemvalorizada
        NATURAL JOIN orden  
        NATURAL JOIN persona   
        NATURAL JOIN consumo
	NATURAL JOIN ordvalorizada 
        LEFT JOIN ordenodonto USING (iditem, centro,nroorden)
--Malapi 25-08-2014 Si se trata de una orden de expendio 2.0 en la matricula se guarda el idprestador y no la matricula
	LEFT JOIN matricula ON ( CASE WHEN trim(ordvalorizada.malcance) = ''  THEN matricula.idprestador = trim(ordvalorizada.nromatricula)::integer ELSE ordvalorizada.nromatricula = matricula.nromatricula AND ordvalorizada.malcance =matricula.malcance AND  ordvalorizada.mespecialidad = matricula.mespecialidad END) 
	LEFT JOIN prestador USING(idprestador)
	WHERE po.idnomenclador='14' AND nrodoc  = $1 AND tipodoc = $2  AND fechaemision>=$3 AND fechaemision <=$4 
*/
	) AS T

	JOIN (SELECT nroorden, centro, MIN(prioridad) as prioridad
	FROM(
	SELECT fichamedicaitememisiones.nroorden,fichamedicaitememisiones.centro, 1 as prioridad
	FROM fichamedica LEFT JOIN fichamedicaitem USING(idfichamedica,idcentrofichamedica) 
	LEFT JOIN fichamedicaitememisiones USING(idfichamedicaitem,idcentrofichamedicaitem) 
	WHERE nrodoc  = $1 AND tipodoc = $2 AND (idauditoriatipo=1 OR idauditoriatipo=2) AND fmifechaauditoria>=$3 AND fmifechaauditoria <=$4 
	UNION
	SELECT orden.nroorden,orden.centro,3 AS prioridad
	FROM item NATURAL JOIN itemvalorizada NATURAL JOIN  consumo NATURAL JOIN orden
	WHERE idnomenclador='14' AND nrodoc  = $1 AND tipodoc = $2 AND fechaemision>=$3 AND fechaemision <=$4) AS TEMPPRI
	GROUP BY nroorden, centro
	) AS TT USING(nroorden,centro, prioridad)
)

	loop

return next rconsumo;

end loop;

end;
$function$
