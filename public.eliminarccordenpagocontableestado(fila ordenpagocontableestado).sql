CREATE OR REPLACE FUNCTION public.eliminarccordenpagocontableestado(fila ordenpagocontableestado)
 RETURNS ordenpagocontableestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontableestadocc:= current_timestamp;
    delete from sincro.ordenpagocontableestado WHERE idordenpagocontableestado= fila.idordenpagocontableestado AND idcentroordenpagocontableestado= fila.idcentroordenpagocontableestado AND TRUE;
    RETURN fila;
    END;
    $function$
