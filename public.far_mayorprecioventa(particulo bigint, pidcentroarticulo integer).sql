CREATE OR REPLACE FUNCTION public.far_mayorprecioventa(particulo bigint, pidcentroarticulo integer)
 RETURNS SETOF far_precioarticulo
 LANGUAGE plpgsql
AS $function$
DECLARE

       particulo alias for $1;
       pidcentroarticulo alias for $2;
       resultado far_precioarticulo%rowtype; 


BEGIN

for resultado in select far_precioarticulo.* FROM far_precioarticulo 
				NATURAL JOIN (
					SELECT idarticulo,idcentroarticulo,max(pavalor) as pavalor
					FROM far_precioarticulo 
					WHERE idarticulo = particulo AND idcentroarticulo = pidcentroarticulo
					GROUP BY idarticulo,idcentroarticulo
					)  as t
				ORDER BY pamodificacion DESC
				LIMIT 1 
loop

return next resultado;
end loop;
return;



END;
$function$
