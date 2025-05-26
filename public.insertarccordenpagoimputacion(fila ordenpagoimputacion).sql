CREATE OR REPLACE FUNCTION public.insertarccordenpagoimputacion(fila ordenpagoimputacion)
 RETURNS ordenpagoimputacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagoimputacioncc:= current_timestamp;
    UPDATE sincro.ordenpagoimputacion SET codigo= fila.codigo, debe= fila.debe, haber= fila.haber, idcentroordenpago= fila.idcentroordenpago, nrocuentac= fila.nrocuentac, nroordenpago= fila.nroordenpago, ordenpagoimputacioncc= fila.ordenpagoimputacioncc WHERE codigo= fila.codigo AND idcentroordenpago= fila.idcentroordenpago AND nroordenpago= fila.nroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpagoimputacion(codigo, debe, haber, idcentroordenpago, nrocuentac, nroordenpago, ordenpagoimputacioncc) VALUES (fila.codigo, fila.debe, fila.haber, fila.idcentroordenpago, fila.nrocuentac, fila.nroordenpago, fila.ordenpagoimputacioncc);
    END IF;
    RETURN fila;
    END;
    $function$
