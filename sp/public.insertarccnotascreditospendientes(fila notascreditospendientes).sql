CREATE OR REPLACE FUNCTION public.insertarccnotascreditospendientes(fila notascreditospendientes)
 RETURNS notascreditospendientes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.notascreditospendientescc:= current_timestamp;
    UPDATE sincro.notascreditospendientes SET centro= fila.centro, notascreditospendientescc= fila.notascreditospendientescc, nrodoc= fila.nrodoc, nroorden= fila.nroorden, tipodoc= fila.tipodoc, tpoexpendio= fila.tpoexpendio WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.notascreditospendientes(centro, notascreditospendientescc, nrodoc, nroorden, tipodoc, tpoexpendio) VALUES (fila.centro, fila.notascreditospendientescc, fila.nrodoc, fila.nroorden, fila.tipodoc, fila.tpoexpendio);
    END IF;
    RETURN fila;
    END;
    $function$
