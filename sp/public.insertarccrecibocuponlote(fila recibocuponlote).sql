CREATE OR REPLACE FUNCTION public.insertarccrecibocuponlote(fila recibocuponlote)
 RETURNS recibocuponlote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocuponlotecc:= current_timestamp;
    UPDATE sincro.recibocuponlote SET idrecibocupon= fila.idrecibocupon, idposnet= fila.idposnet, idcentrorecibocupon= fila.idcentrorecibocupon, nrolote= fila.nrolote, nrocomercio= fila.nrocomercio, recibocuponlotecc= fila.recibocuponlotecc WHERE idrecibocupon= fila.idrecibocupon AND idcentrorecibocupon= fila.idcentrorecibocupon AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibocuponlote(idrecibocupon, idposnet, idcentrorecibocupon, nrolote, nrocomercio, recibocuponlotecc) VALUES (fila.idrecibocupon, fila.idposnet, fila.idcentrorecibocupon, fila.nrolote, fila.nrocomercio, fila.recibocuponlotecc);
    END IF;
    RETURN fila;
    END;
    $function$
