CREATE OR REPLACE FUNCTION public.eliminarccordenrecibo_vinculada(fila ordenrecibo_vinculada)
 RETURNS ordenrecibo_vinculada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenrecibo_vinculadacc:= current_timestamp;
    delete from sincro.ordenrecibo_vinculada WHERE idordenrecibovinculada= fila.idordenrecibovinculada AND idcentroordenrecibovinculada= fila.idcentroordenrecibovinculada AND TRUE;
    RETURN fila;
    END;
    $function$
