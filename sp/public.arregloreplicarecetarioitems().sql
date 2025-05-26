CREATE OR REPLACE FUNCTION public.arregloreplicarecetarioitems()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--cursor
	crecetarioitem refcursor;
        crecetarioitemnulo refcursor;

--record
	existere RECORD;
	rrecetarioitem RECORD;
        rrecetarioitemnulo RECORD;
	rdupl RECORD;

--variables
       sql_update VARCHAR;


BEGIN
  -- sql_update  ='UPDATE recetarioitem set idcentrorecetarioitem=5 WHERE idrecetarioitem=rrecetarioitem.idrecetarioitem';

    ALTER TABLE recetarioitem  ADD COLUMN idcentrorecetarioitem integer;
    ALTER TABLE recetarioitem    ALTER COLUMN centro DROP DEFAULT;

    OPEN crecetarioitem FOR  SELECT  DISTINCT ON(idrecetarioitem) idrecetarioitem,nrorecetario, mnroregistro  FROM recetarioitem where (idrecetarioitem) IN ( SELECT DISTINCT idrecetarioitem FROM recetarioitem
                                   JOIN (select ri.idrecetarioitem,count(*)  from recetarioitem  as ri  GROUP BY ri.idrecetarioitem HAVING count(*) >1) AS T 
                                   USING(idrecetarioitem) )
                            -- and idrecetarioitem<=133420
                             ORDER BY idrecetarioitem;


   FETCH crecetarioitem into rrecetarioitem;
   WHILE  FOUND LOOP

	UPDATE recetarioitem set idcentrorecetarioitem=1 WHERE 
                             idrecetarioitem=rrecetarioitem.idrecetarioitem AND nrorecetario =rrecetarioitem.nrorecetario AND 
                                  mnroregistro=rrecetarioitem.mnroregistro;         
    
        FETCH crecetarioitem into rrecetarioitem;
        END LOOP;
        CLOSE crecetarioitem;


 OPEN crecetarioitemnulo FOR  SELECT  *   FROM recetarioitem where (idrecetarioitem) IN ( SELECT DISTINCT idrecetarioitem FROM recetarioitem
                                   JOIN (select ri.idrecetarioitem,count(*)  from recetarioitem  as ri  GROUP BY ri.idrecetarioitem HAVING count(*) >1) AS T 
                                   USING(idrecetarioitem) )
                           --    and idrecetarioitem<=133420
                             AND nullvalue(idcentrorecetarioitem)
                             ORDER BY idrecetarioitem;


   FETCH crecetarioitemnulo into rrecetarioitemnulo;
   WHILE  FOUND LOOP

	UPDATE recetarioitem set idcentrorecetarioitem=5 WHERE 
                             idrecetarioitem=rrecetarioitemnulo.idrecetarioitem  AND nullvalue(idcentrorecetarioitem);         

        FETCH crecetarioitemnulo into rrecetarioitemnulo;
        END LOOP;
        CLOSE crecetarioitemnulo;

ALTER TABLE recetarioitem DROP CONSTRAINT recetarioitem_pkey;


return 	true;
END;
$function$
