CREATE OR REPLACE FUNCTION public.insertarccanticipobenef(fila anticipobenef)
 RETURNS anticipobenef
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipobenefcc:= current_timestamp;
    UPDATE sincro.anticipobenef SET anio= fila.anio, anticipobenefcc= fila.anticipobenefcc, barra= fila.barra, idcentroregional= fila.idcentroregional, nroanticipo= fila.nroanticipo, nrodoc= fila.nrodoc WHERE nrodoc= fila.nrodoc AND barra= fila.barra AND nroanticipo= fila.nroanticipo AND anio= fila.anio AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.anticipobenef(anio, anticipobenefcc, barra, idcentroregional, nroanticipo, nrodoc) VALUES (fila.anio, fila.anticipobenefcc, fila.barra, fila.idcentroregional, fila.nroanticipo, fila.nrodoc);
    END IF;
    RETURN fila;
    END;
    $function$
