CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionitem(fila informefacturacionitem)
 RETURNS informefacturacionitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionitemcc:= current_timestamp;
    UPDATE sincro.informefacturacionitem SET nrocuentac= fila.nrocuentac, idcentroinformefacturacion= fila.idcentroinformefacturacion, idinformefacturacionitem= fila.idinformefacturacionitem, cantidad= fila.cantidad, importe= fila.importe, descripcion= fila.descripcion, idiva= fila.idiva, nroinforme= fila.nroinforme, idcentroinformefacturacionitem= fila.idcentroinformefacturacionitem, informefacturacionitemcc= fila.informefacturacionitemcc WHERE idinformefacturacionitem= fila.idinformefacturacionitem AND idcentroinformefacturacionitem= fila.idcentroinformefacturacionitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionitem(nrocuentac, idcentroinformefacturacion, idinformefacturacionitem, cantidad, importe, descripcion, idiva, nroinforme, idcentroinformefacturacionitem, informefacturacionitemcc) VALUES (fila.nrocuentac, fila.idcentroinformefacturacion, fila.idinformefacturacionitem, fila.cantidad, fila.importe, fila.descripcion, fila.idiva, fila.nroinforme, fila.idcentroinformefacturacionitem, fila.informefacturacionitemcc);
    END IF;
    RETURN fila;
    END;
    $function$
