CREATE OR REPLACE FUNCTION public.insertarccprestamocuotas(fila prestamocuotas)
 RETURNS prestamocuotas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamocuotascc:= current_timestamp;
    UPDATE sincro.prestamocuotas SET anticipo= fila.anticipo, fechapagoprobable= fila.fechapagoprobable, idcentroprestamo= fila.idcentroprestamo, idcentroprestamocuota= fila.idcentroprestamocuota, idcentrorecibo= fila.idcentrorecibo, idcomprobantetipos= fila.idcomprobantetipos, idformapagotipos= fila.idformapagotipos, idprestamo= fila.idprestamo, idprestamocuotas= fila.idprestamocuotas, idrecibo= fila.idrecibo, importecuota= fila.importecuota, importeinteres= fila.importeinteres, interes= fila.interes, pcborrado= fila.pcborrado, pcidiva= fila.pcidiva, prestamocuotascc= fila.prestamocuotascc WHERE idprestamocuotas= fila.idprestamocuotas AND idcentroprestamocuota= fila.idcentroprestamocuota AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestamocuotas(anticipo, fechapagoprobable, idcentroprestamo, idcentroprestamocuota, idcentrorecibo, idcomprobantetipos, idformapagotipos, idprestamo, idprestamocuotas, idrecibo, importecuota, importeinteres, interes, pcborrado, pcidiva, prestamocuotascc) VALUES (fila.anticipo, fila.fechapagoprobable, fila.idcentroprestamo, fila.idcentroprestamocuota, fila.idcentrorecibo, fila.idcomprobantetipos, fila.idformapagotipos, fila.idprestamo, fila.idprestamocuotas, fila.idrecibo, fila.importecuota, fila.importeinteres, fila.interes, fila.pcborrado, fila.pcidiva, fila.prestamocuotascc);
    END IF;
    RETURN fila;
    END;
    $function$
