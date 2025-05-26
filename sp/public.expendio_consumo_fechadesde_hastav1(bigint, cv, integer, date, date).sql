CREATE OR REPLACE FUNCTION public.expendio_consumo_fechadesde_hastav1(bigint, character varying, integer, date, date)
 RETURNS SETOF type_consumos
 LANGUAGE plpgsql
AS $function$DECLARE

rrecibovuelve  type_consumos ;
rsql VARCHAR;
BEGIN

rsql=concat('
              SELECT orden.nroorden, orden.centro, orden.fechaemision::date, orden.tipo, orden.idasocconv,
    orden.asi, item.idnomenclador, item.idcapitulo, item.idsubcapitulo
    , item.idpractica,CASE WHEN cobertura > 0 THEN cantidad ELSE 0 END as cantidad,idplancovertura::integer
    FROM orden
   NATURAL JOIN consumo
   NATURAL JOIN ordvalorizada
   NATURAL JOIN itemvalorizada
   NATURAL JOIN item
   LEFT JOIN ordenestados USING(nroorden,centro)
   WHERE nullvalue(ordenestados.nroorden) AND idplancovertura = ', $1, ' AND nrodoc= ''',$2
             , ''' AND tipodoc =', $3, 
                     ' AND fechaemision >=''', $4, ''' AND fechaemision <= ''',$5


  ,'''  
   UNION
   SELECT orden.nroorden, orden.centro, orden.fechaemision::date, orden.tipo, orden.idasocconv, orden.asi, ''12'' AS idnomenclador
         , ''42'' AS idcapitulo, ''01'' AS idsubcapitulo, ''01'' AS idpractica, 
         1 as cantidad,idplancovertura::integer
           FROM orden
   NATURAL JOIN consumo
   NATURAL JOIN ordconsulta
   LEFT JOIN ordenestados USING(nroorden,centro)
   WHERE nullvalue(ordenestados.nroorden) AND idplancovertura = ', $1, 
   --- AND (  ' ,   dardatosgrupofamiliar($2,$3),')   --- 30/05/2024 PA-BA. Se modifica para un afiliado y no el grupo familiar
   'AND nrodoc = ''',$2,'''
   AND fechaemision >=''', $4, ''' AND fechaemision <= ''',$5,'''



');



 FOR rrecibovuelve IN 
    EXECUTE(rsql)
    LOOP
   return next rrecibovuelve;
 END LOOP;
 

END;
$function$
