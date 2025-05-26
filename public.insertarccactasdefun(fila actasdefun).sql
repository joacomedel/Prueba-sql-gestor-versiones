CREATE OR REPLACE FUNCTION public.insertarccactasdefun(fila actasdefun)
 RETURNS actasdefun
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.actasdefuncc:= current_timestamp;
    UPDATE sincro.actasdefun SET actasdefuncc= fila.actasdefuncc, adfechapresento= fila.adfechapresento, adffechafallecio= fila.adffechafallecio, barra= fila.barra, nrodoc= fila.nrodoc, presento= fila.presento, tipodoc= fila.tipodoc WHERE tipodoc= fila.tipodoc AND nrodoc= fila.nrodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.actasdefun(actasdefuncc, adfechapresento, adffechafallecio, barra, nrodoc, presento, tipodoc) VALUES (fila.actasdefuncc, fila.adfechapresento, fila.adffechafallecio, fila.barra, fila.nrodoc, fila.presento, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
