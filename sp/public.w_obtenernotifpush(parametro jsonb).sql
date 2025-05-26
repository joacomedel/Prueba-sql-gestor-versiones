CREATE OR REPLACE FUNCTION public.w_obtenernotifpush(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
	vnombreusr varchar;
	vidusrweb bigint;
	notificaciones jsonb;
	
	respuestajson jsonb;
BEGIN
	vnombreusr = parametro ->> 'nombreusr';
	IF (vnombreusr IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos obtenerNotifPush, revíselos y envíelos nuevamente; Se requiere {"nombreusr":"strnombre"}';
	END IF;

	-- sl 11/08/23 - Agrego posiblidad de obtener notificaciones para prestadores
	SELECT INTO vidusrweb idusuarioweb
		FROM w_usuarioweb
			LEFT JOIN  w_usuarioafiliado USING (idusuarioweb)
			LEFT JOIN persona as p	USING (nrodoc)
			LEFT JOIN usuario ON (p.nrodoc = usuario.dni AND p.tipodoc = usuario.tipodoc)
		WHERE (login = vnombreusr OR  uwnombre = vnombreusr OR nullvalue(vnombreusr))
			AND uwactivo --AND uwtipo <> 3
		GROUP BY idusuarioweb,nombres,p.apellido;
	
	SELECT INTO notificaciones json_agg(tablaNotifs)
		FROM (
			--sl 29/02/24 - Agrego todos los campos para manipular la notificacion
			SELECT contenidoNotif as notificacion, sensible, conflectura, interno, 	idnotif, 
                               CASE WHEN nullvalue(fechaenvio) THEN fechacarga ELSE fechaenvio END as fechaenvio -- SL 20/12/24 - MODIFICAR Y CAMBIAR cuando se suba el "worker"
				FROM log_notificaciones
				WHERE idusuarioweb = vidusrweb
				AND eliminado IS NULL -- sl 04/10/23 - Agrego para que no traiga las notificaciones eliminadas
				ORDER BY CASE WHEN sensible = true AND conflectura IS NULL THEN 0 ELSE 1 END, -- sl 04/10/23 - Ordeno por las que no fueron confirmadas y son importantes primero
				         CASE WHEN sensible = true THEN 1 ELSE 2 END, -- sl 04/10/23 - Ordeno por las que si fueron confirmadas y son importantes segundo
				 fechacarga DESC
				--LIMIT 10
		) AS tablaNotifs;
	IF notificaciones IS NOT NULL THEN
		respuestajson = concat('{"notificaciones":',notificaciones,'}');
	ELSE 
		respuestajson = '{"notificaciones":[]}';
	END IF;

	RETURN respuestajson;
END
$function$
