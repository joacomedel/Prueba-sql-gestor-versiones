CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostockitemstockajuste(fila far_movimientostockitemstockajuste)
 RETURNS far_movimientostockitemstockajuste
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemstockajustecc:= current_timestamp;
    delete from sincro.far_movimientostockitemstockajuste WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idcentrostockajuste= fila.idcentrostockajuste AND idmovimientostockitem= fila.idmovimientostockitem AND idstockajusteitem= fila.idstockajusteitem AND TRUE;
    RETURN fila;
    END;
    $function$
