CREATE OR REPLACE FUNCTION public.w_gestioncuentaextendida(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /*
	SELECT * FROM public.w_gestioncuentaextendida('{"datosws":{datosws},"accion":"ACCION_WS","idcliente":"movil","versionapp":"0.1.0"}')
*/
DECLARE
	respuestaws jsonb;
	respuestajson jsonb;
	
	vaccion varchar;
	vdatosws jsonb;
	versionapp varchar;
	vcliente varchar;
BEGIN
	vaccion = parametro ->> 'accion';
	vdatosws = parametro ->> 'datosws';

	versionapp = parametro->>'versionapp';	
	IF versionapp IS NULL THEN
		versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
	END IF;
	/* vcliente = parametro->>'idcliente'; */		
	
	IF (vaccion IS NULL OR vdatosws IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END IF;
	
	CASE vaccion
		WHEN 'registrarCuentaExtendida' 
			THEN respuestaws = public.w_registrocuentaextendida(vdatosws);
			
		WHEN 'obtenerCuentasExtendidas'
			THEN respuestaws = public.w_obtenercuentasextendidas(vdatosws);
			
		WHEN 'desvincularCuentaExtendida'
			THEN respuestaws = public.w_desvincularcuenta(vdatosws);
			
		WHEN 'reactivarCuentaExtendida'
			THEN respuestaws = public.w_reactivarcuenta(vdatosws);
			
		ELSE 
			RAISE EXCEPTION 'R-002, Acción inválida para el WS gestionCuentaExtendida, inténtelo nuevamente. Acción: %', vaccion;
	END CASE;
			
	respuestajson = concat('{ "versionapp":"', versionapp, '", "', vaccion, '": ', respuestaws, '}');
	return respuestajson;
END
$function$
