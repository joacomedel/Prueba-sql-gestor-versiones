CREATE OR REPLACE FUNCTION public.far_cantconsumida_rtpi(bigint, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE
  --variables
  cantconsumida INTEGER;
  elidrecetariotpitem alias for $1;
  elidcentrorecetariotpitem alias for $2;

BEGIN


SELECT INTO cantconsumida case when nullvalue(SUM(ovicantidad))  then 0 else SUM(ovicantidad) end
                            FROM recetario  NATURAL JOIN recetariotpitem NATURAL JOIN recetariotpitemuso  
                            NATURAL JOIN far_ordenventa  JOIN far_medicamento USING(mnroregistro, nomenclado) 
                            NATURAL JOIN far_ordenventaitem 
                            NATURAL JOIN   far_ordenventaestado 
                            WHERE idordenventaestadotipo<>2 and nullvalue(ovefechafin) 
                            AND idrecetariotpitem= elidrecetariotpitem AND idcentrorecetariotpitem=elidcentrorecetariotpitem;


return cantconsumida;
END;$function$
