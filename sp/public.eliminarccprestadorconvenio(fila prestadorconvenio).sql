CREATE OR REPLACE FUNCTION public.eliminarccprestadorconvenio(fila prestadorconvenio)
 RETURNS prestadorconvenio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorconveniocc:= current_timestamp;
    delete from sincro.prestadorconvenio WHERE idconvenio= fila.idconvenio AND idprestador= fila.idprestador AND TRUE;
    RETURN fila;
    END;
    $function$
