CREATE OR REPLACE FUNCTION public.insertarccbarras(fila barras)
 RETURNS barras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.barrascc:= current_timestamp;
    UPDATE sincro.barras SET barra= fila.barra, barrascc= fila.barrascc, nrodoc= fila.nrodoc, prioridad= fila.prioridad, tipodoc= fila.tipodoc WHERE barra= fila.barra AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.barras(barra, barrascc, nrodoc, prioridad, tipodoc) VALUES (fila.barra, fila.barrascc, fila.nrodoc, fila.prioridad, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
