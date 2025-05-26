CREATE OR REPLACE FUNCTION public.far_articulovendido(bigint, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/*
Calcula la cantidad de articulos vendidos en Copahue
*/

DECLARE
	cantartvendidos integer;
	
	elidarticulo bigint;
	elidcentroarticulo integer;

BEGIN
     elidarticulo = $1;
     elidcentroarticulo = $2;

     SELECT INTO cantartvendidos sum(cantidad - ovcantdevueltas) as cant
     FROM far_ordenventaitemitemfacturaventa
     NATURAL JOIN far_ordenventaitem
     NATURAL JOIN itemfacturaventa
     WHERE idarticulo = elidarticulo and idcentroarticulo=elidcentroarticulo
     and idcentroordenventaitem=14 and nrosucursal =16
     GROUP BY idcentroarticulo,idarticulo;

RETURN cantartvendidos;
END;
$function$
