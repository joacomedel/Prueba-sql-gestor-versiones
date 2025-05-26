CREATE OR REPLACE FUNCTION public.far_precioventafecha(particulo bigint, pidcentroarticulo integer, pfecha date)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       pfecha alias for $3;
       precio FLOAT;


BEGIN

SELECT INTO precio CASE WHEN nullvalue(pavalor) THEN 0 ELSE pavalor END + CASE WHEN nullvalue(pimporteiva) THEN 0 ELSE pimporteiva END
from far_precioarticulo 
where ((pafechaini <= pfecha AND (pafechafin >= pfecha OR nullvalue(pafechafin)) ) 
OR (pafechaini >= pfecha)
) AND idarticulo = particulo  AND idcentroarticulo = pidcentroarticulo
ORDER BY idprecioarticulo  ASC
LIMIT 1;


IF nullvalue(precio) THEN
precio = 0;
END IF;

RETURN precio;
END;
$function$
