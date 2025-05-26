CREATE OR REPLACE FUNCTION public.far_cantidadarticuloscomprados(particulo bigint, pidcentroarticulo integer, pfechadesde date, pfechahasta date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       pfechadesde alias for $3;
       pfechahasta alias for $4;

       pcantidad INTEGER;


BEGIN

--idsigno < 0 Resta en NQN entonces SUMA en Copahue
--idsigno > 0 Suma en NQN entonces RESTA en Copahue

SELECT INTO pcantidad SUM(CASE WHEN nullvalue(saicantidad) THEN 0 ELSE saicantidad END)
from far_stockajuste 
natural join far_stockajusteitem
where sadescripcion ilike 'GA - Proceso de Migracion por pedido %' AND safecha >= pfechadesde AND safecha <= pfechahasta
AND idarticulo = particulo AND idcentroarticulo =pidcentroarticulo
GROUP BY idarticulo,idcentroarticulo;


IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;
$function$
