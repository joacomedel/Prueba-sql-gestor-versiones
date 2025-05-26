CREATE OR REPLACE FUNCTION public.w_app_datosgestionbeneficio(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* SELECT  w_app_datosgestionbeneficio('{}')
*/
DECLARE
    respuestajson jsonb;

BEGIN

    SELECT INTO respuestajson jsonb_build_object(
		'localidad', (
			SELECT jsonb_agg(t)
			FROM (SELECT * FROM localidad ORDER BY descrip) AS t
		),
		'entidad', (
			SELECT jsonb_agg(benefseccion)
			FROM (
				SELECT jsonb_build_object(
						'idbeneficioentidad', idbeneficioentidad,
						'benombre', benombre,
						'bedescripcion', bedescripcion,
						'becuit', becuit,
						'berorden', berorden,
						'seccion', berdescripcion,
                        'bebaja', bebaja,
                        'idbeneficioentidadrubro', idbeneficioentidadrubro
					) AS benefseccion
				FROM w_beneficioentidad
				NATURAL JOIN w_beneficioentidadrubro
				ORDER BY benombre
			) AS t
		),
		'rubro', (
			SELECT jsonb_agg(t)
			FROM (SELECT * FROM w_beneficioentidadrubro ORDER BY berorden) AS t
		)
	);

    RETURN respuestajson;
END;
 
$function$
