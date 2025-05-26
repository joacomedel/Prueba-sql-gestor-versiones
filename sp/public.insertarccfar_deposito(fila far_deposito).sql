CREATE OR REPLACE FUNCTION public.insertarccfar_deposito(fila far_deposito)
 RETURNS far_deposito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_depositocc:= current_timestamp;
    UPDATE sincro.far_deposito SET dcomentario= fila.dcomentario, ddescripcion= fila.ddescripcion, far_depositocc= fila.far_depositocc, idcentrodeposito= fila.idcentrodeposito, iddeposito= fila.iddeposito WHERE idcentrodeposito= fila.idcentrodeposito AND iddeposito= fila.iddeposito AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_deposito(dcomentario, ddescripcion, far_depositocc, idcentrodeposito, iddeposito) VALUES (fila.dcomentario, fila.ddescripcion, fila.far_depositocc, fila.idcentrodeposito, fila.iddeposito);
    END IF;
    RETURN fila;
    END;
    $function$
