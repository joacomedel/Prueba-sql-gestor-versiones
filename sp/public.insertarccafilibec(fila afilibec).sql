CREATE OR REPLACE FUNCTION public.insertarccafilibec(fila afilibec)
 RETURNS afilibec
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilibeccc:= current_timestamp;
    UPDATE sincro.afilibec SET afilibeccc= fila.afilibeccc, idresolbe= fila.idresolbe, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilibec(afilibeccc, idresolbe, nrodoc, tipodoc) VALUES (fila.afilibeccc, fila.idresolbe, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
