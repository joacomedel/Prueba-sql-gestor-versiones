CREATE OR REPLACE FUNCTION public.insertarccfar_precargastockajusteitem(fila far_precargastockajusteitem)
 RETURNS far_precargastockajusteitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargastockajusteitemcc:= current_timestamp;
    UPDATE sincro.far_precargastockajusteitem SET far_precargastockajusteitemcc= fila.far_precargastockajusteitemcc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem, idcentrostockajuste= fila.idcentrostockajuste, idprecargastockajusteitem= fila.idprecargastockajusteitem, idstockajuste= fila.idstockajuste, psaiaifechaingreso= fila.psaiaifechaingreso, psaiborrado= fila.psaiborrado, psaicantidadcontada= fila.psaicantidadcontada, psaidescripcion= fila.psaidescripcion, psaiidusuario= fila.psaiidusuario, psaiinformado= fila.psaiinformado, psaistocksistema= fila.psaistocksistema WHERE idprecargastockajusteitem= fila.idprecargastockajusteitem AND idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargastockajusteitem(far_precargastockajusteitemcc, idarticulo, idcentroarticulo, idcentroprecargastockajusteitem, idcentrostockajuste, idprecargastockajusteitem, idstockajuste, psaiaifechaingreso, psaiborrado, psaicantidadcontada, psaidescripcion, psaiidusuario, psaiinformado, psaistocksistema) VALUES (fila.far_precargastockajusteitemcc, fila.idarticulo, fila.idcentroarticulo, fila.idcentroprecargastockajusteitem, fila.idcentrostockajuste, fila.idprecargastockajusteitem, fila.idstockajuste, fila.psaiaifechaingreso, fila.psaiborrado, fila.psaicantidadcontada, fila.psaidescripcion, fila.psaiidusuario, fila.psaiinformado, fila.psaistocksistema);
    END IF;
    RETURN fila;
    END;
    $function$
