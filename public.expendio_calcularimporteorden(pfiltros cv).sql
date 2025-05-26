CREATE OR REPLACE FUNCTION public.expendio_calcularimporteorden(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
 

--RECORD    
rfiltros RECORD; 
ritem RECORD;  

--VARIABLES 
vimporteco DOUBLE PRECISION;
vimpafiliado DOUBLE PRECISION;
vtotalafiliado  DOUBLE PRECISION;
respuesta varchar;
 
BEGIN

  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

  IF (rfiltros.idformapagotipos=6) THEN

      SELECT INTO respuesta  round( sum(case when nullvalue(iicoberturasosuncauditada) then iicoberturasosuncexpendida else iicoberturasosuncauditada end *importe)::numeric, 2) 
      FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion  NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
      WHERE nroorden =rfiltros.nroorden AND centro= rfiltros.centro AND idusuarioweb<>1062 and idusuarioweb<>2942  /*and  iditemestadotipo<>3 */ AND orden.tipo=56
      GROUP BY nroorden,centro; 

 END IF;
  IF (rfiltros.idformapagotipos=2 or rfiltros.idformapagotipos=3) THEN

      SELECT INTO respuesta   sum((1 - case when nullvalue(iicoberturasosuncauditada) and iicoberturasosuncexpendida<>0 then iicoberturasosuncexpendida
    when (nullvalue(iicoberturasosuncauditada) or iicoberturasosuncauditada=0) and iicoberturasosuncexpendida=0 then 1 
   else iicoberturasosuncauditada end -case when nullvalue(iicoberturaamuc) then 0 when iicoberturaamuc <0.1 then iicoberturaamuc*100 else iicoberturaamuc end)*importe)
 
   
FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion  NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
   WHERE nroorden =rfiltros.nroorden AND centro= rfiltros.centro AND idusuarioweb<>1062  and idusuarioweb<>2942  /*and  iditemestadotipo<>3 */ AND orden.tipo=56;
 END IF;
  IF (rfiltros.idformapagotipos=1) THEN

     SELECT INTO respuesta importeamuc
         FROM (
       SELECT nroorden,centro,1 idformapagotipos, sum( (case when nullvalue(iicoberturaamuc) then 0 when iicoberturaamuc <0.1 then iicoberturaamuc*100 else iicoberturaamuc end )  * iiimporteunitario) as importeamuc
       FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
       WHERE  nroorden =rfiltros.nroorden AND centro= rfiltros.centro AND idusuarioweb<>1062 and idusuarioweb<>2942 /*and  iditemestadotipo<>3 */ AND orden.tipo=56
       GROUP BY nroorden,centro  ) AS T;
        --MaLAPi 29-03-2022 saco, pues cuando no hay cobertura de amuc, tiene que devolver cero
       --WHERE T.importeamuc<>0;

 END IF;
 
return respuesta;

END;
$function$
