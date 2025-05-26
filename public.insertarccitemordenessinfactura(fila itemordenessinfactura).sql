CREATE OR REPLACE FUNCTION public.insertarccitemordenessinfactura(fila itemordenessinfactura)
 RETURNS itemordenessinfactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemordenessinfacturacc:= current_timestamp;
    UPDATE sincro.itemordenessinfactura SET cantidad= fila.cantidad, centro= fila.centro, descripcion= fila.descripcion, idconcepto= fila.idconcepto, importe= fila.importe, itemordenessinfacturacc= fila.itemordenessinfacturacc, nroorden= fila.nroorden WHERE centro= fila.centro AND idconcepto= fila.idconcepto AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.itemordenessinfactura(cantidad, centro, descripcion, idconcepto, importe, itemordenessinfacturacc, nroorden) VALUES (fila.cantidad, fila.centro, fila.descripcion, fila.idconcepto, fila.importe, fila.itemordenessinfacturacc, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
