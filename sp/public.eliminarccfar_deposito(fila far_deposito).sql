CREATE OR REPLACE FUNCTION public.eliminarccfar_deposito(fila far_deposito)
 RETURNS far_deposito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_depositocc:= current_timestamp;
    delete from sincro.far_deposito WHERE idcentrodeposito= fila.idcentrodeposito AND iddeposito= fila.iddeposito AND TRUE;
    RETURN fila;
    END;
    $function$
