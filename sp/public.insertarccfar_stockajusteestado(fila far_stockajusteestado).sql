CREATE OR REPLACE FUNCTION public.insertarccfar_stockajusteestado(fila far_stockajusteestado)
 RETURNS far_stockajusteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteestadocc:= current_timestamp;
    UPDATE sincro.far_stockajusteestado SET idstockajuste= fila.idstockajuste, idusuario= fila.idusuario, eaefechaini= fila.eaefechaini, idcentrostockajuste= fila.idcentrostockajuste, far_stockajusteestadocc= fila.far_stockajusteestadocc, eaefechafin= fila.eaefechafin, idstockajusteestado= fila.idstockajusteestado, idstockajusteestadotipo= fila.idstockajusteestadotipo WHERE idstockajusteestado= fila.idstockajusteestado AND idcentrostockajuste= fila.idcentrostockajuste AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajusteestado(idstockajuste, idusuario, eaefechaini, idcentrostockajuste, far_stockajusteestadocc, eaefechafin, idstockajusteestado, idstockajusteestadotipo) VALUES (fila.idstockajuste, fila.idusuario, fila.eaefechaini, fila.idcentrostockajuste, fila.far_stockajusteestadocc, fila.eaefechafin, fila.idstockajusteestado, fila.idstockajusteestadotipo);
    END IF;
    RETURN fila;
    END;
    $function$
