CREATE OR REPLACE FUNCTION public.far_abmordenventaitemvale()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
        cordenventaitemvale  refcursor;
        rordenventaitemvale record;
        rordenventaitem record;
        cantsolicitada integer; 
        cantentregada integer; 

BEGIN

 

              
              OPEN cordenventaitemvale FOR SELECT * FROM  tfar_ordenventaitemvale;
              FETCH cordenventaitemvale into rordenventaitemvale;
              WHILE  found LOOP

                       SELECT INTO cantsolicitada ovicantidad  FROM  far_ordenventaitem     
                       WHERE idordenventaitem=rordenventaitemvale.idordenventaitemvale AND idcentroordenventaitem=rordenventaitemvale.idcentroordenventaitemvale; 
  
                   
		      UPDATE far_ordenventaitemvale SET ovivcantidadentregada=case when nullvalue(ovivcantidadentregada) then 0 else ovivcantidadentregada end +rordenventaitemvale.ovivcantidadentregada 
                      WHERE idordenventaitemvale=rordenventaitemvale.idordenventaitemvale AND idcentroordenventaitemvale=rordenventaitemvale.idcentroordenventaitemvale; 

                      SELECT INTO rordenventaitem * FROM  far_ordenventaitemvale    WHERE idordenventaitemvale=rordenventaitemvale.idordenventaitemvale AND idcentroordenventaitemvale=rordenventaitemvale.idcentroordenventaitemvale; 
                              IF (rordenventaitem.ovivcantidadentregada=cantsolicitada) THEN
--UPDATE far_ordenventaitemimportesestado SET oveiiefechafin= NOW()
--     WHERE idordenventaitemimporte=$1 AND  idcentroordenventaitemimporte=$2  AND nullvalue(oveiiefechafin);

                                    INSERT INTO far_ordenventaitemestado(idordenventaestadotipo,idordenventaitem,idcentroordenventaitem,oviedescripcion)
                                     VALUES(18,rordenventaitemvale.idordenventaitemvale,rordenventaitemvale.idcentroordenventaitemvale,'Item Entregado Completamente. ');


                             END IF; 
                    
             FETCH cordenventaitemvale into rordenventaitemvale;
       
              END LOOP;

             close cordenventaitemvale;

     

return true;
END;
$function$
