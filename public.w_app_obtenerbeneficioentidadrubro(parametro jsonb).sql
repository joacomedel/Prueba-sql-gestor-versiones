CREATE OR REPLACE FUNCTION public.w_app_obtenerbeneficioentidadrubro(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* SP que se utiliza en w_app_gestionbeneficioentidad
*/
DECLARE
    --RECORD
	rrespuesta RECORD;
	--VARIABLES
	respuestajson jsonb;

BEGIN
	--Busco los datos
	SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS entidad
	FROM ( 
		SELECT * FROM w_beneficioentidadrubro
	) AS t;

	respuestajson = rrespuesta.entidad;

	RETURN respuestajson;
END;

$function$
