CREATE OR REPLACE FUNCTION public.far_darcantidadarticulostock(particulo bigint, pidcentroarticulo integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       pcantidad INTEGER;


BEGIN

SELECT INTO pcantidad SUM(lstock)as cantstock            
FROM far_lote            
WHERE idarticulo = particulo AND idcentroarticulo = pidcentroarticulo
AND idcentrolote = centro() --Malapi 02-12-2014 Modifico para que solo muestre la cantidad de articulos que hay en la sucursal
GROUP BY idarticulo,idcentroarticulo;


IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;
$function$
