CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostockitemstockajuste(fila far_movimientostockitemstockajuste)
 RETURNS far_movimientostockitemstockajuste
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemstockajustecc:= current_timestamp;
    UPDATE sincro.far_movimientostockitemstockajuste SET far_movimientostockitemstockajustecc= fila.far_movimientostockitemstockajustecc, idcentromovimientostockitem= fila.idcentromovimientostockitem, idcentrostockajuste= fila.idcentrostockajuste, idmovimientostockitem= fila.idmovimientostockitem, idstockajusteitem= fila.idstockajusteitem WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idcentrostockajuste= fila.idcentrostockajuste AND idmovimientostockitem= fila.idmovimientostockitem AND idstockajusteitem= fila.idstockajusteitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostockitemstockajuste(far_movimientostockitemstockajustecc, idcentromovimientostockitem, idcentrostockajuste, idmovimientostockitem, idstockajusteitem) VALUES (fila.far_movimientostockitemstockajustecc, fila.idcentromovimientostockitem, fila.idcentrostockajuste, fila.idmovimientostockitem, fila.idstockajusteitem);
    END IF;
    RETURN fila;
    END;
    $function$
