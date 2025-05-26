CREATE OR REPLACE FUNCTION public.eliminarccordenpagocontable(fila ordenpagocontable)
 RETURNS ordenpagocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontablecc:= current_timestamp;
    delete from sincro.ordenpagocontable WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND TRUE;
    RETURN fila;
    END;
    $function$
