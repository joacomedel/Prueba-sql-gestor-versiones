CREATE OR REPLACE FUNCTION public.insertarcclibroconrecibo(fila libroconrecibo)
 RETURNS libroconrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.libroconrecibocc:= current_timestamp;
    UPDATE sincro.libroconrecibo SET mesrecibo= fila.mesrecibo, prestador= fila.prestador, idrecepcion= fila.idrecepcion, montorecibo= fila.montorecibo, quincena= fila.quincena, libroconrecibocc= fila.libroconrecibocc, numeroexpte= fila.numeroexpte, idcentroregional= fila.idcentroregional, numerorecibo= fila.numerorecibo WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.libroconrecibo(mesrecibo, prestador, idrecepcion, montorecibo, quincena, libroconrecibocc, numeroexpte, idcentroregional, numerorecibo) VALUES (fila.mesrecibo, fila.prestador, fila.idrecepcion, fila.montorecibo, fila.quincena, fila.libroconrecibocc, fila.numeroexpte, fila.idcentroregional, fila.numerorecibo);
    END IF;
    RETURN fila;
    END;
    $function$
