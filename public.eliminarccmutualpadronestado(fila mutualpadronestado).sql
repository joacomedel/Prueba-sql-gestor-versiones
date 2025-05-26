CREATE OR REPLACE FUNCTION public.eliminarccmutualpadronestado(fila mutualpadronestado)
 RETURNS mutualpadronestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mutualpadronestadocc:= current_timestamp;
    delete from sincro.mutualpadronestado WHERE idcentromutualpadronestado= fila.idcentromutualpadronestado AND idmutualpadronestado= fila.idmutualpadronestado AND TRUE;
    RETURN fila;
    END;
    $function$
