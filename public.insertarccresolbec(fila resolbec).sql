CREATE OR REPLACE FUNCTION public.insertarccresolbec(fila resolbec)
 RETURNS resolbec
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.resolbeccc:= current_timestamp;
    UPDATE sincro.resolbec SET fechafinlab= fila.fechafinlab, fechainilab= fila.fechainilab, idcateg= fila.idcateg, iddepen= fila.iddepen, idresolbe= fila.idresolbe, nroresol= fila.nroresol, resolbeccc= fila.resolbeccc WHERE idresolbe= fila.idresolbe AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.resolbec(fechafinlab, fechainilab, idcateg, iddepen, idresolbe, nroresol, resolbeccc) VALUES (fila.fechafinlab, fila.fechainilab, fila.idcateg, fila.iddepen, fila.idresolbe, fila.nroresol, fila.resolbeccc);
    END IF;
    RETURN fila;
    END;
    $function$
