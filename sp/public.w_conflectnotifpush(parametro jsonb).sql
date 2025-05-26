CREATE OR REPLACE FUNCTION public.w_conflectnotifpush(parametro jsonb)
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

	-- Verifico que no este confirmada anteriormente
	SELECT INTO respuestanotif * FROM log_notificaciones WHERE idnotif = vidnotif AND conflectura IS NULL;
	IF FOUND THEN
		UPDATE log_notificaciones
			SET conflectura = now(),
			visto = now()
		WHERE idnotif = vidnotif;
	ELSE
		--Aviso que ya fue confirmada
		RAISE EXCEPTION 'R-003, La notificacion ya fue notificada como leída.';
	END IF;

	-- Verifico que se haya notificado
	SELECT INTO respuestanotif * FROM log_notificaciones WHERE idnotif = vidnotif AND conflectura IS NOT NULL;
	IF FOUND THEN
		-- Traigo notificaciones actualizadas
		respuestajson =  public.w_obtenerNotifPush(parametro);
	ELSE 
		--Fallo la confirmacion
		RAISE EXCEPTION 'R-002, No se pudo confirmar la notificacion. Intentelo mas tarde nuevamente o contactese con sistema.';
	END IF;

	RETURN respuestajson;
END;
$function$
