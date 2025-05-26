CREATE OR REPLACE FUNCTION public.insertarccfacturacionfechas(fila facturacionfechas)
 RETURNS facturacionfechas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturacionfechascc:= current_timestamp;
    UPDATE sincro.facturacionfechas SET anio= fila.anio, facturacionfechascc= fila.facturacionfechascc, ffechafin= fila.ffechafin, ffechaini= fila.ffechaini, nroregistro= fila.nroregistro WHERE anio= fila.anio AND ffechafin= fila.ffechafin AND ffechaini= fila.ffechaini AND nroregistro= fila.nroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturacionfechas(anio, facturacionfechascc, ffechafin, ffechaini, nroregistro) VALUES (fila.anio, fila.facturacionfechascc, fila.ffechafin, fila.ffechaini, fila.nroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
