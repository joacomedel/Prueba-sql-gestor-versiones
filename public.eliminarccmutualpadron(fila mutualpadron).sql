CREATE OR REPLACE FUNCTION public.eliminarccmutualpadron(fila mutualpadron)
 RETURNS mutualpadron
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mutualpadroncc:= current_timestamp;
    delete from sincro.mutualpadron WHERE idcentromutualpadron= fila.idcentromutualpadron AND idmutualpadron= fila.idmutualpadron AND TRUE;
    RETURN fila;
    END;
    $function$
