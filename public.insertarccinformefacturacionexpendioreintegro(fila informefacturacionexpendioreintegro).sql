CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionexpendioreintegro(fila informefacturacionexpendioreintegro)
 RETURNS informefacturacionexpendioreintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionexpendioreintegrocc:= current_timestamp;
    UPDATE sincro.informefacturacionexpendioreintegro SET anio= fila.anio, idcentroinformefacturacion= fila.idcentroinformefacturacion, idcentroregional= fila.idcentroregional, informefacturacionexpendioreintegrocc= fila.informefacturacionexpendioreintegrocc, nroinforme= fila.nroinforme, nroreintegro= fila.nroreintegro WHERE nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionexpendioreintegro(anio, idcentroinformefacturacion, idcentroregional, informefacturacionexpendioreintegrocc, nroinforme, nroreintegro) VALUES (fila.anio, fila.idcentroinformefacturacion, fila.idcentroregional, fila.informefacturacionexpendioreintegrocc, fila.nroinforme, fila.nroreintegro);
    END IF;
    RETURN fila;
    END;
    $function$
