CREATE OR REPLACE FUNCTION public.estadisticapracticaimporte(character varying, character varying, integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   pfechadesde varchar;
   pfechahasta varchar;
   pidplancob integer;
   pnrodoc varchar;
   ptipodoc integer;
      
BEGIN

 pfechadesde  =$1;
 pfechahasta =$2;
 pidplancob =$3;
 pnrodoc =$4;
 ptipodoc  =$5;

CREATE TEMP TABLE temptepi(
                   tipo varchar,
                   idcomp varchar,
                   fechaemision date,
                   idpractica varchar,                   
                   descripcion varchar,
                   importeafiliado double PRECISION,
                   importeauditado double PRECISION,
                  -- importesosunc double PRECISION,
                   estadocomp varchar,
                   descripplan varchar,
                   nrodoc varchar,
                   tipodoc integer,
                   descriptipodoc varchar,                   
                   idafiliado varchar, 
                   nombreafiliado varchar
                 ) WITH OIDS;


INSERT INTO temptepi (

SELECT TT.*,tiposdoc.descrip, concat(nrodoc, ' - ', barra) as idafiliado, concat(apellido, ', ', nombres) as nbreafil
FROM (

SELECT 'Reintegro' as tipo,concat(nroreintegro,'-',anio,'-',idcentroregional) as idreintegro, rfechaingreso, '' as idtipoprest, tipoprestaciondesc,  importe as importeafiliado ,0 as importeauditado, estadoreintegrodesc,'' as descripplan,
reintegro.nrodoc, reintegro.tipodoc 
FROM reintegro NATURAL JOIN reintegroprestacion NATURAL JOIN (SELECT nroreintegro, anio, idcentroregional, estadoreintegrodesc FROM restados NATURAL JOIN tipoestadosreintegro ORDER BY idcambioestado ) as a NATURAL JOIN tipoprestacion
WHERE rfechaingreso>= pfechadesde AND  rfechaingreso<= pfechahasta  AND (reintegro.nrodoc=pnrodoc OR  nullvalue(pnrodoc)) 
             AND (reintegro.tipodoc=ptipodoc OR  nullvalue(ptipodoc)) 

UNION 

SELECT  CASE WHEN gratuito THEN 'Med.Gratuito' WHEN imporden.tipo=37 THEN 'Recetario TP'ELSE 'Medicamento' END as tipo,concat(imporden.nroorden,'-',imporden.centro) as idrecetario, fechauso, 
'98.01.01.01'as idpractica,
CONCAT( CASE WHEN nullvalue(mnombre) THEN '' ELSE CONCAT(mnombre, '-' ,mpresentacion) END,
CASE WHEN nullvalue(pdescripcion) THEN 'Recetario sin Usar' ELSE pdescripcion END ) AS descrece,
pvch.importe as importeafiliado,fmpaiimportes as importeauditado,  CASE WHEN anulado THEN  'Anulado' ELSE '' END  AS anulado,
plancobertura.descripcion as descripplan,consumo.nrodoc, consumo.tipodoc 
FROM 
( SELECT nrorecetario as nroorden,recetario.centro,idplancovertura,idrecetarioitem,idcentrorecetarioitem,idasocconv,CASE WHEN (tipo = 4 OR tipo=53) THEN 14 ELSE tipo END as tipo,importe, idfarmacia, idprestador as idprestadorotro ,recetario.fechaemision,gratuito, fechauso
  FROM recetario LEFT JOIN recetarioitem USING(nrorecetario,centro) 
  LEFT JOIN orden ON nrorecetario = nroorden AND recetario.centro = orden.centro
  WHERE recetario.fechaemision>= pfechadesde AND  recetario.fechaemision<= pfechahasta AND (recetario.nrodoc=pnrodoc OR nullvalue(pnrodoc)) 
    AND (recetario.tipodoc=ptipodoc OR nullvalue(ptipodoc)) AND (idplancovertura=pidplancob OR 0=pidplancob)
  ) as imporden 


JOIN plancobertura ON ( idplancovertura=idplancobertura)
JOIN consumo ON consumo.nroorden = imporden.nroorden and consumo.centro = imporden.centro
LEFT JOIN  fichamedicapreauditadaitemrecetario AS fmir
ON(imporden.idrecetarioitem=fmir.idrecetarioitem AND imporden.idcentrorecetarioitem=fmir.idcentrorecetarioitem AND imporden.centro=fmir.centro  )
LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
LEFT JOIN  medicamento USING(mnroregistro)
LEFT JOIN laboratorio USING(idlaboratorio)
LEFT join prestador on(idfarmacia=prestador.idprestador)

LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON( imporden.idasocconv =pvch.idasocconv AND
pvch.idsubespecialidad ='98' AND pvch.idcapitulo = '01'  AND pvch.idsubcapitulo = '01' AND  pvch.idpractica = '01'  AND pvch.pcategoria = 'A' AND
pvxchfechaini>=imporden.fechaemision AND (pvxchfechafin<=imporden.fechaemision  or nullvalue(pvxchfechafin)))


WHERE imporden.fechaemision>= pfechadesde AND  imporden.fechaemision<= pfechahasta AND (consumo.nrodoc=pnrodoc OR nullvalue(pnrodoc)) 
             AND (consumo.tipodoc=ptipodoc OR nullvalue(ptipodoc))  AND not anulado AND (idplancovertura=pidplancob OR 0=pidplancob)

UNION 

SELECT ctdescripcion, concat( T.nroorden, '-' , T.centro) as laorden, fechaemision, 
CONCAT(T.idnomenclador,'.', T.idcapitulo,'.',T.idsubcapitulo,'.', T.idpractica ) as idpractica,pdescripcion as  descriptrat,pvch.importe as importeafiliado, importeauditado,  CASE WHEN anulado THEN  'Anulado' ELSE '' END  AS anulado,plancobertura.descripcion as descripplan,  
consumo.nrodoc, consumo.tipodoc
--, CASE WHEN (idformapagotipos=6) THEN io.importe END as importesosunc
FROM
(

SELECT orden.nroorden, orden.centro, orden.fechaemision, orden.tipo,item.idnomenclador, item.idcapitulo, item.idsubcapitulo, item.idpractica, null as descriptrat, cantidad, itemvalorizada.idplancovertura,orden.idasocconv, fmpaiimportes as importeauditado
FROM orden NATURAL JOIN ordvalorizada NATURAL JOIN itemvalorizada NATURAL JOIN item NATURAL JOIN practica
LEFT JOIN fichamedicapreauditadaitem 
ON(itemvalorizada.iditem = fichamedicapreauditadaitem.iditem AND itemvalorizada.centro=fichamedicapreauditadaitem.centro AND itemvalorizada.nroorden=fichamedicapreauditadaitem.nroorden)
LEFT JOIN fichamedicapreauditada as a USING(idcentrofichamedicapreauditada,idfichamedicapreauditada) 
WHERE  fechaemision>= pfechadesde AND  fechaemision<=pfechahasta AND (idplancovertura=pidplancob OR pidplancob=0)

UNION

SELECT orden.nroorden, orden.centro, orden.fechaemision, orden.tipo, '12' as idnomenclador, '42' as idcapitulo, '01' as idsubcapitulo, '01' as idpractica, 'Consultas' as descriptrat, 1 as cantidad, idplancovertura,orden.idasocconv, fmpaiimportes as importeauditado
FROM orden NATURAL JOIN ordconsulta    LEFT JOIN  fichamedicapreauditadaitemconsulta USING(nroorden,centro) 
 LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
WHERE fechaemision>=pfechadesde AND  fechaemision<=pfechahasta  AND (idplancovertura=pidplancob OR pidplancob=0)

UNION

SELECT orden.nroorden, orden.centro, orden.fechaemision, orden.tipo, '0' as idnomenclador, '0' as idcapitulo, '0' as idsubcapitulo, '0' as idpractica, 
CONCAT(to_char(fechainternacion,'DD-MM-YYYY') , ' ', lugarinternacion, ' Tipo Internacion: ' , desctipo,' ', diagnostico) as descriptrat
 ,cantdias as cantidad,idplancovertura,orden.idasocconv, 0 as  importeauditado
FROM orden NATURAL JOIN ordinternacion JOIN tipointernacion ON idtipo = tipointernacion 
WHERE fechaemision>=pfechadesde AND  fechaemision<=pfechahasta AND (idplancovertura=pidplancob OR pidplancob=0)

UNION

SELECT laordenv.nroorden, laordenv.centro, orden.fechaemision, orden.tipo, item.idnomenclador,  item.idcapitulo, item.idsubcapitulo, item.idpractica, concat(orden.nroorden ,' - ', orden.centro) as descriptrat,  cantidad, iv.idplancovertura,orden.idasocconv, fmpaiimportes as importeauditado
FROM orden NATURAL JOIN ordinternacion JOIN orden as laordenv ON (orden.nroorden= laordenv.nroordeninter AND orden.centro= laordenv.centroordeninter) JOIN ordvalorizada as ov ON (laordenv.nroorden=ov.nroorden AND laordenv.centro=ov.centro) 
JOIN itemvalorizada AS iv ON (laordenv.nroorden=iv.nroorden AND laordenv.centro=iv.centro) JOIN item ON (iv.centro=item.centro AND iv.iditem=item.iditem) NATURAL JOIN practica 

 LEFT JOIN fichamedicapreauditadaitem 
 ON(iv.iditem = fichamedicapreauditadaitem.iditem AND iv.centro=fichamedicapreauditadaitem.centro AND iv.nroorden=fichamedicapreauditadaitem.nroorden)
LEFT JOIN fichamedicapreauditada as a USING(idcentrofichamedicapreauditada,idfichamedicapreauditada) 


WHERE laordenv.fechaemision>=pfechadesde AND  laordenv.fechaemision<=pfechahasta  AND (iv.idplancovertura=pidplancob OR pidplancob=0)


) AS T NATURAL JOIN consumo JOIN comprobantestipos ON comprobantestipos.idcomprobantetipos = T.tipo
-- NATURAL JOIN importesorden as io 
NATURAL JOIN practica
JOIN plancobertura ON ( idplancovertura=idplancobertura) 
/* JOIN practicavalores AS pv ON 
(T.idnomenclador=pv.idsubespecialidad AND T.idcapitulo=pv.idcapitulo AND  T.idsubcapitulo=pv.idsubcapitulo AND T.idpractica=pv.idpractica AND T.idasocconv=pv.idasocconv)
*/
LEFT JOIN  practicavaloresxcategoriahistorico as pvch ON( T.idasocconv =pvch.idasocconv AND
pvch.idsubespecialidad = T.idnomenclador AND pvch.idcapitulo = T.idcapitulo  AND pvch.idsubcapitulo = T.idsubcapitulo AND  pvch.idpractica = T.idpractica  AND pvch.pcategoria = 'A' AND
pvxchfechaini>=T.fechaemision AND (pvxchfechafin<=T.fechaemision  or nullvalue(pvxchfechafin)))

--LEFT JOIN  ordenesutilizadas AS ou USING(nroorden, centro, tipo)
LEFT JOIN ordenestados USING(nroorden,centro) 
LEFT JOIN ordenestadotipos using(idordenestadotipos)

WHERE (nrodoc=pnrodoc OR nullvalue(pnrodoc)) AND (tipodoc=ptipodoc OR  nullvalue(ptipodoc)) AND 
--(idformapagotipos=2 or idformapagotipos=3 or idformapagotipos=6) AND 
not anulado
) AS TT NATURAL JOIN persona NATURAL JOIN tiposdoc
);


RETURN true;
END;
$function$
