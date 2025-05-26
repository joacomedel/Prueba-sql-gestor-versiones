CREATE OR REPLACE FUNCTION public.insertarccfar_precioarticulohermano(fila far_precioarticulohermano)
 RETURNS far_precioarticulohermano
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulohermanocc:= current_timestamp;
    UPDATE sincro.far_precioarticulohermano SET idarticulohermano= fila.idarticulohermano, idcentroarticulohermano= fila.idcentroarticulohermano, far_precioarticulohermanocc= fila.far_precioarticulohermanocc, idarticulokairo= fila.idarticulokairo, idcentroarticulokairo= fila.idcentroarticulokairo WHERE idarticulokairo= fila.idarticulokairo AND idarticulohermano= fila.idarticulohermano AND idcentroarticulohermano= fila.idcentroarticulohermano AND idcentroarticulokairo= fila.idcentroarticulokairo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precioarticulohermano(idarticulohermano, idcentroarticulohermano, far_precioarticulohermanocc, idarticulokairo, idcentroarticulokairo) VALUES (fila.idarticulohermano, fila.idcentroarticulohermano, fila.far_precioarticulohermanocc, fila.idarticulokairo, fila.idcentroarticulokairo);
    END IF;
    RETURN fila;
    END;
    $function$
