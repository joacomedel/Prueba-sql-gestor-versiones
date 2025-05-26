CREATE OR REPLACE FUNCTION public.cambiarestadofichamedica(integer, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


/* Se cierra un informe
 * Se pasan por parametro el nro  de idfichamedicaitem y el centro del mismo  y el nuevo estado al cual va a estar el ITEM DE la ficha
*/

   rverifica RECORD;

BEGIN

   -- Cambio el estado de la ficha medica
               --    RAISE NOTICE ' quiero cambier el estado (%) ',$3;
             SELECT INTO rverifica fichamedicaemision.*,idfichamedicaemisionestadotipo FROM fichamedicaemision  LEFT JOIN fichamedicaemisionestado USING(idfichamedicaitem,idcentrofichamedicaitem,idauditoriatipo) WHERE idfichamedicaitem=$1 and idcentrofichamedicaitem=$2 AND nullvalue(fmeefechafin) LIMIT 1; 
             IF FOUND AND (nullvalue(rverifica.idfichamedicaemisionestadotipo) OR  rverifica.idfichamedicaemisionestadotipo <> $3) THEN 
                 --  RAISE NOTICE ' Inserte el estado (%) ',$3;
                      UPDATE fichamedicaemisionestado
                      SET fmeefechafin=NOW()
                      WHERE idfichamedicaitem=$1 and idcentrofichamedicaitem=$2 and nullvalue(fmeefechafin);

             INSERT INTO fichamedicaemisionestado(idfichamedicaitem,idcentrofichamedicaitem,idauditoriatipo,idfichamedicaemisionestadotipo,fmeefechaini,fmeedescripcion)
             VALUES($1,$2,rverifica.idauditoriatipo, $3,now(),$4);

            END IF;
return true;
END;
$function$
