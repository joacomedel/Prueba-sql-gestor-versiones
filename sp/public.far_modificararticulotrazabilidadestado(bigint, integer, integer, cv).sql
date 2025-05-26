CREATE OR REPLACE FUNCTION public.far_modificararticulotrazabilidadestado(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
BEGIN
         
	UPDATE far_articulotrazabilidadestado SET atefechafin = NOW()
	WHERE nullvalue(atefechafin) AND idarticulotraza= $1 AND idcentroarticulotraza = $2;

        INSERT INTO far_articulotrazabilidadestado( idarticulotrazabilidadestadotipos, idarticulotraza, idcentroarticulotraza, atedescripcion)
		VALUES ($3, $1, $2, $4);
        
 RETURN true;     
END;

$function$
