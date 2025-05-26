CREATE OR REPLACE FUNCTION public.insertarccfar_stockajusteiteminformado(fila far_stockajusteiteminformado)
 RETURNS far_stockajusteiteminformado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteiteminformadocc:= current_timestamp;
    UPDATE sincro.far_stockajusteiteminformado SET far_stockajusteiteminformadocc= fila.far_stockajusteiteminformadocc, idcentrostockajusteitem= fila.idcentrostockajusteitem, idcentrostockajusteiteminformado= fila.idcentrostockajusteiteminformado, idstockajusteitem= fila.idstockajusteitem, idstockajusteiteminformado= fila.idstockajusteiteminformado, idstockajusteiteminformetipo= fila.idstockajusteiteminformetipo, saiifecharesuelto= fila.saiifecharesuelto, saiiidusuarioresolvio= fila.saiiidusuarioresolvio, saiiobservacion= fila.saiiobservacion, saiiresuelto= fila.saiiresuelto WHERE idstockajusteiteminformado= fila.idstockajusteiteminformado AND idcentrostockajusteiteminformado= fila.idcentrostockajusteiteminformado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajusteiteminformado(far_stockajusteiteminformadocc, idcentrostockajusteitem, idcentrostockajusteiteminformado, idstockajusteitem, idstockajusteiteminformado, idstockajusteiteminformetipo, saiifecharesuelto, saiiidusuarioresolvio, saiiobservacion, saiiresuelto) VALUES (fila.far_stockajusteiteminformadocc, fila.idcentrostockajusteitem, fila.idcentrostockajusteiteminformado, fila.idstockajusteitem, fila.idstockajusteiteminformado, fila.idstockajusteiteminformetipo, fila.saiifecharesuelto, fila.saiiidusuarioresolvio, fila.saiiobservacion, fila.saiiresuelto);
    END IF;
    RETURN fila;
    END;
    $function$
