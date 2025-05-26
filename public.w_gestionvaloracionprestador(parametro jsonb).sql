CREATE OR REPLACE FUNCTION public.w_gestionvaloracionprestador(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /* SELECT * FROM public.w_gestionValoracionPrestador('{ "accion":"(valorarPrestador / obtenerPrestadores)", "datosws":{datosws}, "idcliente": "movil" ,"versionapp": "0.1.0"}')
	datosws obtenerPrestadores -> {"nrodoc":"1234"}
	datosws valorarPrestador -> {"nrodoc":"1234", "idprestador": "4321", "valoracion": (0 - 5), "observacion":"texto observacion"}	
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
	
	versionapp = parametro ->> 'versionapp';
	IF versionapp IS NULL THEN
		versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
	END IF;
	
	IF (vaccion IS NULL OR vdatosws IS NULL) THEN
		RAISE EXCEPTION 'R-001 WS_GestionarValoracion, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %', parametro;		
	END IF;
	
	CASE vaccion
		WHEN 'obtenerPrestadores'
			THEN respuestaws = public.w_obtenerprestadoresafiliado(vdatosws);
		WHEN 'valorarPrestador'
			THEN respuestaws = public.w_valorarprestador(vdatosws);
		ELSE
			RAISE EXCEPTION 'R-002 WS_GestionarValoracion, Acción inválida! Inténtelo nuevamente. Acción: %', vaccion;	
	END CASE;
	
	respuestajson = concat('{"versionapp":"', versionapp, '","', vaccion, '":', respuestaws, '}');
	return respuestajson;	
END
$function$
