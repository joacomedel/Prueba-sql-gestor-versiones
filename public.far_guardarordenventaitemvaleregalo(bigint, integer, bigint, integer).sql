CREATE OR REPLACE FUNCTION public.far_guardarordenventaitemvaleregalo(bigint, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
        cordenventaitemvale  refcursor;
        rordenventaitemvale record;
        rordenventaitemo record;
      

BEGIN

 

              OPEN cordenventaitemvale FOR SELECT * FROM far_ordenventa NATURAL JOIN far_ordenventaitem WHERE idordenventa = $1 AND idcentroordenventa = $2;
              FETCH cordenventaitemvale into rordenventaitemvale;
              WHILE  found LOOP

                     SELECT INTO    rordenventaitemo * FROM far_ordenventaitem WHERE idordenventa = $3 AND idcentroordenventa = $4 
                                  AND idarticulo = rordenventaitemvale.idarticulo AND idcentroarticulo= rordenventaitemvale.idcentroarticulo;
                     IF FOUND THEN 
                        INSERT INTO far_ordenventaitemvaleregalo(idordenventaitemvaleregalo,idcentroordenventaitemvaleregalo,idordenventaitemoriginal,idcentroordenventaitemoriginal)
                        VALUES(rordenventaitemvale.idordenventaitem,rordenventaitemvale.idcentroordenventaitem,rordenventaitemo.idordenventaitem,rordenventaitemo.idcentroordenventaitem);
                     END IF;
                   
                    

              FETCH cordenventaitemvale into rordenventaitemvale;
              END LOOP;

      close cordenventaitemvale;

    -- PERFORM far_modificarvaleitemimportes($1,$2);
return true;
END;
$function$
