CREATE OR REPLACE FUNCTION public.w_obtenertiposvaloraciones(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /* SELECT * FROM public.w_obtenerTiposValoraciones('{"idcliente": "movil" ,"versionapp": "0.1.0"}');*/
DECLARE
	valoraciones jsonb;
	respuestajson jsonb;
	
	versionapp varchar;	
BEGIN
	versionapp = parametro ->> 'versionapp';
	IF versionapp IS NULL THEN
		versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
	END IF;

	SELECT INTO valoraciones json_agg(valoracionesActivas)
		FROM (
			SELECT idtipoval as id, tvnombre as nombre, tvdesc as descripcion, tvactivo as activo, tvtipo as tipo, tvdefault as deflt
			FROM w_tipovaloracion
			WHERE tvactivo
			ORDER BY tvprioridad
	) AS valoracionesActivas;
	
	IF valoraciones IS NULL THEN
		respuestajson = concat('{"versionapp":"', versionapp, '","tipos":[]}');
	ELSE
		respuestajson = concat('{"versionapp":"', versionapp, '","tipos":', valoraciones, '}');	
	END IF;
	
	return respuestajson;
END
$function$
