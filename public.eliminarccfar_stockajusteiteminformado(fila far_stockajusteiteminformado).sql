CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajusteiteminformado(fila far_stockajusteiteminformado)
 RETURNS far_stockajusteiteminformado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteiteminformadocc:= current_timestamp;
    delete from sincro.far_stockajusteiteminformado WHERE idstockajusteiteminformado= fila.idstockajusteiteminformado AND idcentrostockajusteiteminformado= fila.idcentrostockajusteiteminformado AND TRUE;
    RETURN fila;
    END;
    $function$
