CREATE OR REPLACE FUNCTION public.w_traerantnotifpush(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
-- FUNCION UTILIZADA DESDE w_gestionnotifpush
DECLARE
	vidusrweb bigint;
	vnombreusr varchar;
	respuestajson jsonb;
	respuestanotif jsonb;
BEGIN
	vnombreusr = parametro ->> 'nombreusr';
	-- Verifico que recibo el id del usuarioweb
	IF (vnombreusr IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos traerAntNotifPushVista, revíselos y envíelos nuevamente; Se requiere {"vnombreusr":"donJose"}';
	END IF;
	SELECT INTO vidusrweb idusuarioweb
	FROM w_usuarioweb
		LEFT JOIN  w_usuarioafiliado USING (idusuarioweb)
		LEFT JOIN persona as p	USING (nrodoc)
		LEFT JOIN usuario ON (p.nrodoc = usuario.dni AND p.tipodoc = usuario.tipodoc)
	WHERE (login = vnombreusr OR  uwnombre = vnombreusr OR nullvalue(vnombreusr))
		AND uwactivo --AND uwtipo <> 3
	GROUP BY idusuarioweb,nombres,p.apellido;
	IF FOUND THEN
		-- Borro el eliminado de las ultimas 10 notificaciones
		WITH ultimas_notificaciones AS (
			SELECT idnotif
			FROM log_notificaciones
			WHERE idusuarioweb = vidusrweb AND eliminado IS NOT NULL
			ORDER BY fechaenvio DESC
			LIMIT 10
		)
		UPDATE log_notificaciones ln
		SET eliminado = NULL
		FROM ultimas_notificaciones un
		WHERE ln.idnotif = un.idnotif;

		-- Traigo las notificaciones con las 10 antiguas
		respuestanotif =  public.w_obtenerNotifPush(parametro);
		IF respuestanotif IS NOT NULL THEN
			respuestajson = respuestanotif;
		ELSE 
			--Fallo al traer antiguas
			RAISE EXCEPTION 'R-002, No se pudo traer las notificaciones. Intentelo mas tarde nuevamente o contactese con sistema.';
		END IF;
	ELSE
		--Fallo al buscar el id del usuarioweb
		RAISE EXCEPTION 'R-003, No se encontro el usuario en el servidor.';
	END IF;

	RETURN respuestajson;
END;
$function$
