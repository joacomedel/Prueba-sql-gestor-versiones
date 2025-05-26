CREATE OR REPLACE FUNCTION public.far_abmarticuloubicaciondeposito(pidarticulo bigint, pidcentroarticulo integer, pidubicacionsucursal integer, pidcentroubicacionsucursal integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare

	elem record;
begin
     SELECT INTO elem * FROM far_articuloubicacionsucursal 
			WHERE idarticulo = pidarticulo AND idcentroarticulo = pidcentroarticulo 
			AND  idubicacionsucursal = pidubicacionsucursal 
			AND idcentroubicacionsucursal = pidcentroubicacionsucursal
			AND nullvalue(ausfechafin);
     IF NOT FOUND THEN 
	INSERT INTO far_articuloubicaciondeposito(idarticuloubicacionsucursal,idcentroarticuloubicacionsucursal,idarticulo,idcentroarticulo)
	VALUES(pidubicacionsucursal,pidcentroubicacionsucursal,pidarticulo,pidcentroarticulo);
     END IF;
     return true;
end;
$function$
