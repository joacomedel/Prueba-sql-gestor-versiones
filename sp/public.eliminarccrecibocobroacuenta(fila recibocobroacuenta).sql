CREATE OR REPLACE FUNCTION public.eliminarccrecibocobroacuenta(fila recibocobroacuenta)
 RETURNS recibocobroacuenta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocobroacuentacc:= current_timestamp;
    delete from sincro.recibocobroacuenta WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    RETURN fila;
    END;
    $function$
