CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajusteestadotipo(fila far_stockajusteestadotipo)
 RETURNS far_stockajusteestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteestadotipocc:= current_timestamp;
    delete from sincro.far_stockajusteestadotipo WHERE idstockajusteestadotipo= fila.idstockajusteestadotipo AND TRUE;
    RETURN fila;
    END;
    $function$
