CREATE OR REPLACE FUNCTION public.eliminarccctacteprestador(fila ctacteprestador)
 RETURNS ctacteprestador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctacteprestadorcc:= current_timestamp;
    delete from sincro.ctacteprestador WHERE idprestador= fila.idprestador AND TRUE;
    RETURN fila;
    END;
    $function$
