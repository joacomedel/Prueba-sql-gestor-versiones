CREATE OR REPLACE FUNCTION public.far_modificarvaleitemimportes(bigint, integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE
        rordenventa record;
        cordenventaitem  refcursor;
        cordenventaitemimportes  refcursor;
        rordenventaitem record;
        rordenventaitemimportes record;
        rordenventaiio record; 
        rarticulo record;
        rvendedor record;
        codordenventa bigint;
        nroinforme bigint;
        resp boolean;
        voviidiva DOUBLE PRECISION;
        elvendedor integer;
        rrespuesta record;

BEGIN
            
            OPEN cordenventaitem FOR  SELECT fovi.*, fov.*,fovii.*,fov2.idordenventa as idordenventaoriginal,
                                      fov2.idcentroordenventa as idcentroordenventaoriginal
                                      FROM far_ordenventaitemvale AS foviv JOIN far_ordenventaitem AS fovi ON 		
                                      (fovi.idordenventaitem=foviv.idordenventaitemvale 
                                      AND fovi.idcentroordenventaitem=foviv.idcentroordenventaitemvale) 		
                                      JOIN far_ordenventa AS fov ON (fovi.idordenventa=fov.idordenventa 
                                      AND   fovi.idcentroordenventa=fov.idcentroordenventa) 		
                                      JOIN far_ordenventaitemimportes AS fovii ON (fovi.idordenventaitem=fovii.idordenventaitem 
                                      AND  fovi.idcentroordenventaitem=fovii.idcentroordenventaitem) 		
                                      JOIN far_ordenventaitem AS fovi2 ON (fovi2.idordenventaitem=foviv.idordenventaitemoriginal 
                                      AND fovi2.idcentroordenventaitem =foviv.idcentroordenventaitemoriginal) 
                                     JOIN far_ordenventa AS fov2 ON (fovi2.idordenventa=fov2.idordenventa AND fovi2.idcentroordenventa=fov2.idcentroordenventa) 
                            WHERE fov.idordenventa= $1 AND fov.idcentroordenventa= $2;
              FETCH cordenventaitem into rordenventaitem;
              WHILE  found LOOP

                    
                     SELECT INTO rordenventaiio * FROM far_ordenventaitem NATURAL JOIN far_ordenventaitemimportes 
                               WHERE idordenventa= rordenventaitem.idordenventaoriginal AND idcentroordenventa=rordenventaitem.idcentroordenventaoriginal
                               AND idvalorescaja =rordenventaitem.idvalorescaja AND idarticulo = rordenventaitem.idarticulo  AND 
                                idcentroarticulo = rordenventaitem.idcentroarticulo;
                     IF FOUND THEN 
                             UPDATE far_ordenventaitemimportes SET oviimonto = 
                                     round(CAST ((rordenventaiio.oviimonto/rordenventaiio.ovicantidad)*rordenventaitem.ovicantidad AS numeric),2)
                                  
                             WHERE idordenventaitem=rordenventaitem.idordenventaitem  AND idcentroordenventaitem=rordenventaitem.idcentroordenventaitem  
                             AND idvalorescaja =rordenventaitem.idvalorescaja;

                     END IF; 
                     
           
              FETCH cordenventaitem into rordenventaitem;
              END LOOP;

      close cordenventaitem;

    
END;

$function$
