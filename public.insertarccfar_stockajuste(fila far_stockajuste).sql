CREATE OR REPLACE FUNCTION public.insertarccfar_stockajuste(fila far_stockajuste)
 RETURNS far_stockajuste
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajustecc:= current_timestamp;
    UPDATE sincro.far_stockajuste SET far_stockajustecc= fila.far_stockajustecc, idcentrostockajuste= fila.idcentrostockajuste, idstockajuste= fila.idstockajuste, saanulado= fila.saanulado, sadescripcion= fila.sadescripcion, saesautomatico= fila.saesautomatico, safecha= fila.safecha WHERE idcentrostockajuste= fila.idcentrostockajuste AND idstockajuste= fila.idstockajuste AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajuste(far_stockajustecc, idcentrostockajuste, idstockajuste, saanulado, sadescripcion, saesautomatico, safecha) VALUES (fila.far_stockajustecc, fila.idcentrostockajuste, fila.idstockajuste, fila.saanulado, fila.sadescripcion, fila.saesautomatico, fila.safecha);
    END IF;
    RETURN fila;
    END;
    $function$
