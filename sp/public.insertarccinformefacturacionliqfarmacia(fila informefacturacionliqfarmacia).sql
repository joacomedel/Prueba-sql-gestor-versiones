CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionliqfarmacia(fila informefacturacionliqfarmacia)
 RETURNS informefacturacionliqfarmacia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionliqfarmaciacc:= current_timestamp;
    UPDATE sincro.informefacturacionliqfarmacia SET idliquidacion= fila.idliquidacion, nroinforme= fila.nroinforme, idcentroinformefacturacion= fila.idcentroinformefacturacion, idcentroliquidacion= fila.idcentroliquidacion, informefacturacionliqfarmaciacc= fila.informefacturacionliqfarmaciacc WHERE nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionliqfarmacia(idliquidacion, nroinforme, idcentroinformefacturacion, idcentroliquidacion, informefacturacionliqfarmaciacc) VALUES (fila.idliquidacion, fila.nroinforme, fila.idcentroinformefacturacion, fila.idcentroliquidacion, fila.informefacturacionliqfarmaciacc);
    END IF;
    RETURN fila;
    END;
    $function$
