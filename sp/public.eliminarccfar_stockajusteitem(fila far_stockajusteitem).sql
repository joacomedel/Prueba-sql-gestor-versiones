CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajusteitem(fila far_stockajusteitem)
 RETURNS far_stockajusteitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteitemcc:= current_timestamp;
    delete from sincro.far_stockajusteitem WHERE idcentrostockajusteitem= fila.idcentrostockajusteitem AND idstockajusteitem= fila.idstockajusteitem AND TRUE;
    RETURN fila;
    END;
    $function$
