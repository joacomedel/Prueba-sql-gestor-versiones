CREATE OR REPLACE FUNCTION public.insertarccadmusuariostransaccion(fila admusuariostransaccion)
 RETURNS admusuariostransaccion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admusuariostransaccioncc:= current_timestamp;
    UPDATE sincro.admusuariostransaccion SET admusuariostransaccioncc= fila.admusuariostransaccioncc, iditem= fila.iditem, idmenu= fila.idmenu, idmodulo= fila.idmodulo, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idmodulo= fila.idmodulo AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.admusuariostransaccion(admusuariostransaccioncc, iditem, idmenu, idmodulo, nrodoc, tipodoc) VALUES (fila.admusuariostransaccioncc, fila.iditem, fila.idmenu, fila.idmodulo, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
