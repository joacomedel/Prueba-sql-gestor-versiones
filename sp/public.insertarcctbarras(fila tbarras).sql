CREATE OR REPLACE FUNCTION public.insertarcctbarras(fila tbarras)
 RETURNS tbarras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tbarrascc:= current_timestamp;
    UPDATE sincro.tbarras SET nrodoctitu= fila.nrodoctitu, siguiente= fila.siguiente, tbarrascc= fila.tbarrascc, tipodoctitu= fila.tipodoctitu WHERE nrodoctitu= fila.nrodoctitu AND tipodoctitu= fila.tipodoctitu AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tbarras(nrodoctitu, siguiente, tbarrascc, tipodoctitu) VALUES (fila.nrodoctitu, fila.siguiente, fila.tbarrascc, fila.tipodoctitu);
    END IF;
    RETURN fila;
    END;
    $function$
