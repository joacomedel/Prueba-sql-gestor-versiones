CREATE OR REPLACE FUNCTION public.insertarccfar_stockajusteitem(fila far_stockajusteitem)
 RETURNS far_stockajusteitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteitemcc:= current_timestamp;
    UPDATE sincro.far_stockajusteitem SET far_stockajusteitemcc= fila.far_stockajusteitemcc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentrostockajuste= fila.idcentrostockajuste, idcentrostockajusteitem= fila.idcentrostockajusteitem, idsigno= fila.idsigno, idstockajuste= fila.idstockajuste, idstockajusteitem= fila.idstockajusteitem, idusuario= fila.idusuario, saialicuotaiva= fila.saialicuotaiva, saicantidad= fila.saicantidad, saicantidadactual= fila.saicantidadactual, saifechaingreso= fila.saifechaingreso, saifechavencimiento= fila.saifechavencimiento, saiimporteiva= fila.saiimporteiva, saiimportetotal= fila.saiimportetotal, saiimporteunitario= fila.saiimporteunitario WHERE idcentrostockajusteitem= fila.idcentrostockajusteitem AND idstockajusteitem= fila.idstockajusteitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajusteitem(far_stockajusteitemcc, idarticulo, idcentroarticulo, idcentrostockajuste, idcentrostockajusteitem, idsigno, idstockajuste, idstockajusteitem, idusuario, saialicuotaiva, saicantidad, saicantidadactual, saifechaingreso, saifechavencimiento, saiimporteiva, saiimportetotal, saiimporteunitario) VALUES (fila.far_stockajusteitemcc, fila.idarticulo, fila.idcentroarticulo, fila.idcentrostockajuste, fila.idcentrostockajusteitem, fila.idsigno, fila.idstockajuste, fila.idstockajusteitem, fila.idusuario, fila.saialicuotaiva, fila.saicantidad, fila.saicantidadactual, fila.saifechaingreso, fila.saifechavencimiento, fila.saiimporteiva, fila.saiimportetotal, fila.saiimporteunitario);
    END IF;
    RETURN fila;
    END;
    $function$
