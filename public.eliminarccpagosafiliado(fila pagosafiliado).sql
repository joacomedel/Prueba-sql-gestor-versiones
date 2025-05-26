CREATE OR REPLACE FUNCTION public.eliminarccpagosafiliado(fila pagosafiliado)
 RETURNS pagosafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagosafiliadocc:= current_timestamp;
    delete from sincro.pagosafiliado WHERE centro= fila.centro AND idpagos= fila.idpagos AND TRUE;
    RETURN fila;
    END;
    $function$
