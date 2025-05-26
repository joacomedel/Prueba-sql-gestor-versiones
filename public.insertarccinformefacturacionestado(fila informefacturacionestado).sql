CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionestado(fila informefacturacionestado)
 RETURNS informefacturacionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionestadocc:= current_timestamp;
    UPDATE sincro.informefacturacionestado SET descripcion= fila.descripcion, fechafin= fila.fechafin, fechaini= fila.fechaini, idcentroinformefacturacion= fila.idcentroinformefacturacion, idinformefacturacionestado= fila.idinformefacturacionestado, idinformefacturacionestadotipo= fila.idinformefacturacionestadotipo, ifeidusuario= fila.ifeidusuario, informefacturacionestadocc= fila.informefacturacionestadocc, nroinforme= fila.nroinforme WHERE idinformefacturacionestado= fila.idinformefacturacionestado AND nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionestado(descripcion, fechafin, fechaini, idcentroinformefacturacion, idinformefacturacionestado, idinformefacturacionestadotipo, ifeidusuario, informefacturacionestadocc, nroinforme) VALUES (fila.descripcion, fila.fechafin, fila.fechaini, fila.idcentroinformefacturacion, fila.idinformefacturacionestado, fila.idinformefacturacionestadotipo, fila.ifeidusuario, fila.informefacturacionestadocc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
