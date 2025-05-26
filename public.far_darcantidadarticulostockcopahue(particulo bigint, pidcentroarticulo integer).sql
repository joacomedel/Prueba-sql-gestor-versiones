CREATE OR REPLACE FUNCTION public.far_darcantidadarticulostockcopahue(particulo bigint, pidcentroarticulo integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       pcantidad INTEGER;


BEGIN

--idsigno < 0 Resta en NQN entonces SUMA en Copahue
--idsigno > 0 Suma en NQN entonces RESTA en Copahue

SELECT INTO pcantidad SUM(CASE WHEN nullvalue(saicantidad) THEN 0 ELSE saicantidad END*idsigno*-1)
from far_stockajuste 
natural join far_stockajusteitem
where sadescripcion ilike '%copahue%' AND idstockajuste >= 5340
AND idarticulo = particulo AND idcentroarticulo =pidcentroarticulo
GROUP BY idarticulo,idcentroarticulo;


IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;
$function$
