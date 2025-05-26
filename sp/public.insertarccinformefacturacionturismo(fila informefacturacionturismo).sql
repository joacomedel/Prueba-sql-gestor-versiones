CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionturismo(fila informefacturacionturismo)
 RETURNS informefacturacionturismo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionturismocc:= current_timestamp;
    UPDATE sincro.informefacturacionturismo SET idcentroconsumoturismo= fila.idcentroconsumoturismo, idcentroinformefacturacion= fila.idcentroinformefacturacion, idconsumoturismo= fila.idconsumoturismo, informefacturacionturismocc= fila.informefacturacionturismocc, nroinforme= fila.nroinforme WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionturismo(idcentroconsumoturismo, idcentroinformefacturacion, idconsumoturismo, informefacturacionturismocc, nroinforme) VALUES (fila.idcentroconsumoturismo, fila.idcentroinformefacturacion, fila.idconsumoturismo, fila.informefacturacionturismocc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
