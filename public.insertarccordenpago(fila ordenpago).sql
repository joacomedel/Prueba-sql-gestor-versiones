CREATE OR REPLACE FUNCTION public.insertarccordenpago(fila ordenpago)
 RETURNS ordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocc:= current_timestamp;
    UPDATE sincro.ordenpago SET asiento= fila.asiento, beneficiario= fila.beneficiario, concepto= fila.concepto, fechaingreso= fila.fechaingreso, idcentroordenpago= fila.idcentroordenpago, idordenpagotipo= fila.idordenpagotipo, importetotal= fila.importetotal, nrocuentachaber= fila.nrocuentachaber, nroordenpago= fila.nroordenpago, ordenpagocc= fila.ordenpagocc WHERE nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpago(asiento, beneficiario, concepto, fechaingreso, idcentroordenpago, idordenpagotipo, importetotal, nrocuentachaber, nroordenpago, ordenpagocc) VALUES (fila.asiento, fila.beneficiario, fila.concepto, fila.fechaingreso, fila.idcentroordenpago, fila.idordenpagotipo, fila.importetotal, fila.nrocuentachaber, fila.nroordenpago, fila.ordenpagocc);
    END IF;
    RETURN fila;
    END;
    $function$
