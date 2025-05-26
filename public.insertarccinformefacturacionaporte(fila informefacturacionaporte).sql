CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionaporte(fila informefacturacionaporte)
 RETURNS informefacturacionaporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionaportecc:= current_timestamp;
    UPDATE sincro.informefacturacionaporte SET idaporte= fila.idaporte, idcentroinformefacturacion= fila.idcentroinformefacturacion, idcentroregionaluso= fila.idcentroregionaluso, informefacturacionaportecc= fila.informefacturacionaportecc, nroinforme= fila.nroinforme WHERE idaporte= fila.idaporte AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND idcentroregionaluso= fila.idcentroregionaluso AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionaporte(idaporte, idcentroinformefacturacion, idcentroregionaluso, informefacturacionaportecc, nroinforme) VALUES (fila.idaporte, fila.idcentroinformefacturacion, fila.idcentroregionaluso, fila.informefacturacionaportecc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
