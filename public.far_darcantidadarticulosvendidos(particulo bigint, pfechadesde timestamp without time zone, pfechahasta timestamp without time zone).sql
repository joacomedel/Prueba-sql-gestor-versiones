CREATE OR REPLACE FUNCTION public.far_darcantidadarticulosvendidos(particulo bigint, pfechadesde timestamp without time zone, pfechahasta timestamp without time zone)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

       particulo alias for $1;
       pfechadesde alias for $2;
       pfechahasta alias for $3;
       pcantidad INTEGER;


BEGIN

IF(NOT nullvalue(pfechadesde)) THEN
SELECT INTO pcantidad SUM(ovicantidad) as cant 
	 	FROM far_ordenventaitem 
		NATURAL JOIN far_ordenventa 
                NATURAL JOIN far_ordenventaestado  		
		WHERE nullvalue(far_ordenventaestado.ovefechafin) 
                      AND ovfechaemision::date >= pfechadesde
                      AND ovfechaemision::date <= pfechahasta
		      AND idordenventaestadotipo <> 2 
	              AND idarticulo = particulo
group by  idarticulo,idcentroarticulo;



END IF;



IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;
$function$
