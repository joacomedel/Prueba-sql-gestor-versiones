CREATE OR REPLACE FUNCTION public.insertarccmotivodebito(fila motivodebito)
 RETURNS motivodebito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.motivodebitocc:= current_timestamp;
    UPDATE sincro.motivodebito SET idmotivodebito= fila.idmotivodebito, mddescripcion= fila.mddescripcion, motivodebitocc= fila.motivodebitocc WHERE idmotivodebito= fila.idmotivodebito AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.motivodebito(idmotivodebito, mddescripcion, motivodebitocc) VALUES (fila.idmotivodebito, fila.mddescripcion, fila.motivodebitocc);
    END IF;
    RETURN fila;
    END;
    $function$
