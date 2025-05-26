CREATE OR REPLACE FUNCTION public.far_abmarticuloagrupador(pidarticulo bigint, pidcentroarticulo integer, pidagrupador integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare

	elem record;
begin
     SELECT INTO elem * FROM far_articuloagrupador 
			WHERE idarticulo = pidarticulo AND idcentroarticulo = pidcentroarticulo AND nullvalue(aafechafin);
     IF FOUND THEN 
	IF elem.idagrupador <> pidagrupador THEN
		UPDATE far_articuloagrupador SET aafechafin = now() WHERE idarticulo = pidarticulo AND idcentroarticulo = pidcentroarticulo AND nullvalue(aafechafin); 
		INSERT INTO far_articuloagrupador(idagrupador,idarticulo,idcentroarticulo) VALUES(pidagrupador,pidarticulo,pidcentroarticulo);
	END IF;
     ELSE
	INSERT INTO far_articuloagrupador(idagrupador,idarticulo,idcentroarticulo) VALUES(pidagrupador,pidarticulo,pidcentroarticulo);
     END IF;
     return true;
end;
$function$
