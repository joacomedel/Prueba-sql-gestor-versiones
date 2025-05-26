CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajusteestado(fila far_stockajusteestado)
 RETURNS far_stockajusteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteestadocc:= current_timestamp;
    delete from sincro.far_stockajusteestado WHERE idstockajusteestado= fila.idstockajusteestado AND idcentrostockajuste= fila.idcentrostockajuste AND TRUE;
    RETURN fila;
    END;
    $function$
