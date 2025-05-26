CREATE OR REPLACE FUNCTION public.arreglarimportesorden(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--CURSORES
cursoritem refcursor;
cursororden refcursor;

--RECORD    
ritem RECORD;
runitemorden RECORD; 
rtieneimporte RECORD;
rorden RECORD;

--VARIABLES 
res VARCHAR;
laorden BIGINT; 
elcentro INTEGER;  

BEGIN

 
OPEN cursoritem FOR SELECT nroorden, centro, nrodoc, tipodoc, idrecibo from importesorden natural join consumo NATURAL JOIN ordenrecibo where nroorden =1301461 AND centro=1
          GROUP BY nroorden, centro, nrodoc, tipodoc, idrecibo;
FETCH cursoritem INTO ritem;
WHILE  found LOOP

   DELETE FROM importesorden  WHERE nroorden =ritem.nroorden AND centro= ritem.centro;
   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)  
   SELECT nroorden,centro,idformapagotipos,importeamuc FROM (
SELECT nroorden,centro,1 idformapagotipos, sum( (case when nullvalue(iicoberturaamuc) then 0 when iicoberturaamuc <0.1 then iicoberturaamuc*100 else iicoberturaamuc end )  * iiimporteunitario) as importeamuc
   FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
   WHERE nroorden =ritem.nroorden AND centro= ritem.centro AND idusuarioweb<>1062 and idusuarioweb<>2942  and iditemestadotipo<>3
   GROUP BY nroorden,centro  ) AS T
   WHERE T.importeamuc<>0;
  
   
   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)   
   SELECT nroorden,centro,uwpformapagotipodefecto, round(sum((1 - case when nullvalue(iicoberturasosuncauditada) then iicoberturasosuncexpendida else iicoberturasosuncauditada end - case when nullvalue(iicoberturaamuc) then 0 when iicoberturaamuc <0.1 then iicoberturaamuc*100 else iicoberturaamuc end)*importe)::numeric, 2)

FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion  NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
   WHERE nroorden =ritem.nroorden AND centro= ritem.centro  AND idusuarioweb<>1062  and idusuarioweb<>2942  and iditemestadotipo<>3
   GROUP BY nroorden,centro,uwpformapagotipodefecto;

   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)    
   SELECT nroorden,centro,6,round( sum(case when nullvalue(iicoberturasosuncauditada) then iicoberturasosuncexpendida else iicoberturasosuncauditada end *importe)::numeric, 2)   as coberturasosunc

  FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion  NATURAL JOIN orden NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio JOIN w_usuariowebprestador USING(idconvenio) 
   WHERE nroorden =ritem.nroorden AND centro= ritem.centro  AND idusuarioweb<>1062 and idusuarioweb<>2942   and iditemestadotipo<>3
   GROUP BY nroorden,centro;

    DELETE FROM importesrecibo   WHERE  idrecibo = ritem.idrecibo  AND centro = ritem.centro ;
  INSERT INTO importesrecibo ( idrecibo , centro  , idformapagotipos,importe)
                (SELECT idrecibo ,centro ,  idformapagotipos , SUM(importe)
                 FROM importesorden NATURAL JOIN ordenrecibo WHERE  nroorden = ritem.nroorden  AND centro = ritem.centro 
                 GROUP BY idformapagotipos, idrecibo,centro ,  idformapagotipos);

FETCH cursoritem INTO ritem;
END LOOP;
CLOSE cursoritem;
 
    
RETURN '';
END;
$function$
