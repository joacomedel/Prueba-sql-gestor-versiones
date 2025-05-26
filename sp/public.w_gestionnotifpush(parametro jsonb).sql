CREATE OR REPLACE FUNCTION public.w_gestionnotifpush(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
-- SELECT * FROM public.w_gestionNotifPush('{"datosws":{datosws},"accion":"ACCION_WS","idcliente":"movil","versionapp":"0.1.0"}')
DECLARE
	respuestaws jsonb;
	respuestajson jsonb;
	
	vaccion varchar;
	vdatosws jsonb;
	versionapp varchar;
BEGIN
	vaccion = parametro ->> 'accion';
	vdatosws = parametro ->> 'datosws';
	
	versionapp = parametro->>'versionapp';	
	IF versionapp IS NULL THEN
		versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
	END IF;
	
	IF (vaccion IS NULL OR vdatosws IS NULL) THEN
		RAISE EXCEPTION 'R-001 - Parámetros inválidos w_gestionNotifPush, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END IF;
	
	CASE vaccion
		WHEN 'sendNotificacion'
			THEN respuestaws = public.w_enviarNotificacionPush(vdatosws);
		WHEN 'getNotificaciones'
			THEN respuestaws = public.w_obtenerNotifPush(vdatosws);
		WHEN 'getOldNotificaciones'
			THEN respuestaws = public.w_traerantnotifPush(vdatosws);
		WHEN 'deleteNotificacion'
			THEN respuestaws = public.w_eliminarnotifPush(vdatosws);
		WHEN 'deleteNotificacionAll'
            THEN
                -- Elimino la notificaciones
                UPDATE log_notificaciones
                    SET eliminado = now(), 
                    visto = now()
                WHERE idusuarioweb = vdatosws->>'idusuarioweb' AND nullvalue(eliminado) AND (sensible = FALSE OR NOT nullvalue(conflectura));

                -- Traigo notificaciones actualizadas
                respuestaws =  public.w_obtenerNotifPush(vdatosws);
        WHEN 'conflectNotificacion'
			THEN respuestaws = public.w_conflectnotifpush(vdatosws);
		ELSE
			RAISE EXCEPTION 'R-002, Acción inválida WS gestionNotifPush, inténtelo nuevamente. Acción: %', vaccion;
	END CASE;
	
	respuestajson = concat('{ "versionapp":"', versionapp, '", "', vaccion, '": ', respuestaws, '}');
	RETURN respuestajson;
END;
$function$
