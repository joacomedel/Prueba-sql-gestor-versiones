CREATE OR REPLACE FUNCTION public.eliminarccpagoordenpagocontable(fila pagoordenpagocontable)
 RETURNS pagoordenpagocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoordenpagocontablecc:= current_timestamp;
    delete from sincro.pagoordenpagocontable WHERE idcentropagoordenpagocontable= fila.idcentropagoordenpagocontable AND idpagoordenpagocontable= fila.idpagoordenpagocontable AND TRUE;
    RETURN fila;
    END;
    $function$
