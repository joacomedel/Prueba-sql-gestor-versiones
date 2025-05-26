CREATE OR REPLACE FUNCTION public.w_eliminarnotifpush(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
-- FUNCION UTILIZADA DESDE w_gestionnotifpush
DECLARE
	vidnotif bigint;
	respuestajson jsonb;
	respuestanotif RECORD;
BEGIN
	vidnotif = parametro ->> 'idnotif';
	-- Verifico que recibo el id de la notificacion
	IF (vidnotif IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos eliminarNotifPush, revíselos y envíelos nuevamente; Se requiere {"idnotif":"123"}';
	END IF;

	-- Verifico que no este vista anteriormente
	SELECT INTO respuestanotif * FROM log_notificaciones WHERE idnotif = vidnotif AND visto IS NULL;
	-- Elimino la notificacion
	IF FOUND THEN
		UPDATE log_notificaciones
			SET eliminado = now(), 
			visto = now()
		WHERE idnotif = vidnotif;
	ELSE
		UPDATE log_notificaciones
			SET eliminado = now()
		WHERE idnotif = vidnotif;
	END IF;

	-- Verifico que se haya borrado
	SELECT INTO respuestanotif * FROM log_notificaciones WHERE idnotif = vidnotif AND eliminado IS NOT NULL;
	IF FOUND THEN
		-- Traigo notificaciones actualizadas
		respuestajson =  public.w_obtenerNotifPush(parametro);
	ELSE 
		--Fallo la eliminacion
		RAISE EXCEPTION 'R-002, No se pudo eliminar la notificacion. Intentelo mas tarde nuevamente o contactese con sistema.';
	END IF;

	RETURN respuestajson;
END;
$function$
