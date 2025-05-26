CREATE OR REPLACE FUNCTION public.insertarcchistobarras(fila histobarras)
 RETURNS histobarras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.histobarrascc:= current_timestamp;
    UPDATE sincro.histobarras SET barra= fila.barra, fechafin= fila.fechafin, fechaini= fila.fechaini, histobarrascc= fila.histobarrascc, nrodoc= fila.nrodoc, prioridad= fila.prioridad, tipodoc= fila.tipodoc WHERE barra= fila.barra AND fechaini= fila.fechaini AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.histobarras(barra, fechafin, fechaini, histobarrascc, nrodoc, prioridad, tipodoc) VALUES (fila.barra, fila.fechafin, fila.fechaini, fila.histobarrascc, fila.nrodoc, fila.prioridad, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
