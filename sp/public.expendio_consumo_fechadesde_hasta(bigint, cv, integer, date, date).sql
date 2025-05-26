CREATE OR REPLACE FUNCTION public.expendio_consumo_fechadesde_hasta(bigint, character varying, integer, date, date)
 RETURNS SETOF type_consumos
 LANGUAGE sql
AS $function$
SELECT orden.nroorden, orden.centro, orden.fechaemision::date, orden.tipo, orden.idasocconv,
    orden.asi, item.idnomenclador, item.idcapitulo, item.idsubcapitulo
    , item.idpractica, cantidad,idplancovertura::integer
    FROM orden
   NATURAL JOIN consumo
   NATURAL JOIN ordvalorizada
   NATURAL JOIN itemvalorizada
   NATURAL JOIN item
   LEFT JOIN ordenestados USING(nroorden,centro)
   WHERE nullvalue(ordenestados.nroorden) AND idplancovertura = $1
   AND nrodoc=$2 AND tipodoc = $3 AND fechaemision >= $4 AND fechaemision <= $5
UNION
   SELECT orden.nroorden, orden.centro, orden.fechaemision::date, orden.tipo, orden.idasocconv, orden.asi, '12' AS idnomenclador
         , '42' AS idcapitulo, '01' AS idsubcapitulo, '01' AS idpractica, 
         1 as cantidad,idplancovertura::integer
           FROM orden
   NATURAL JOIN consumo
   NATURAL JOIN ordconsulta
   LEFT JOIN ordenestados USING(nroorden,centro)
   WHERE nullvalue(ordenestados.nroorden) AND idplancovertura = $1
   AND nrodoc=$2 AND tipodoc = $3 AND fechaemision >= $4 AND fechaemision <= $5
$function$
