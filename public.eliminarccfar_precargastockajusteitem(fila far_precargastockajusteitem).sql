CREATE OR REPLACE FUNCTION public.eliminarccfar_precargastockajusteitem(fila far_precargastockajusteitem)
 RETURNS far_precargastockajusteitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargastockajusteitemcc:= current_timestamp;
    delete from sincro.far_precargastockajusteitem WHERE idprecargastockajusteitem= fila.idprecargastockajusteitem AND idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem AND TRUE;
    RETURN fila;
    END;
    $function$
