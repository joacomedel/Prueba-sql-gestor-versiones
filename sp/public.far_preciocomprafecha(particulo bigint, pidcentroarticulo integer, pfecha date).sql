CREATE OR REPLACE FUNCTION public.far_preciocomprafecha(particulo bigint, pidcentroarticulo integer, pfecha date)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       pfecha alias for $3;
       precio FLOAT;


BEGIN

SELECT INTO precio CASE WHEN nullvalue(preciocompra) THEN 0 ELSE preciocompra END
from far_preciocompra
where (
         (pcfechafini <= pfecha AND (pcfechafin >= pfecha OR nullvalue(pcfechafin)) )
       )
       AND idarticulo = particulo  AND idcentroarticulo = pidcentroarticulo
ORDER BY idpreciocompra  ASC
LIMIT 1;


IF nullvalue(precio) THEN
precio = 0;
END IF;

RETURN precio;
END;
$function$
