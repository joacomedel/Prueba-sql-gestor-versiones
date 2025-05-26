CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajuste(fila far_stockajuste)
 RETURNS far_stockajuste
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajustecc:= current_timestamp;
    delete from sincro.far_stockajuste WHERE idcentrostockajuste= fila.idcentrostockajuste AND idstockajuste= fila.idstockajuste AND TRUE;
    RETURN fila;
    END;
    $function$
