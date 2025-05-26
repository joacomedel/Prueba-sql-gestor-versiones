CREATE OR REPLACE FUNCTION public.insertarccordenessinfacturas(fila ordenessinfacturas)
 RETURNS ordenessinfacturas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenessinfacturascc:= current_timestamp;
    UPDATE sincro.ordenessinfacturas SET centro= fila.centro, nrodoc= fila.nrodoc, nroorden= fila.nroorden, ordenessinfacturascc= fila.ordenessinfacturascc, tipodoc= fila.tipodoc, tpoexpendio= fila.tpoexpendio WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenessinfacturas(centro, nrodoc, nroorden, ordenessinfacturascc, tipodoc, tpoexpendio) VALUES (fila.centro, fila.nrodoc, fila.nroorden, fila.ordenessinfacturascc, fila.tipodoc, fila.tpoexpendio);
    END IF;
    RETURN fila;
    END;
    $function$
