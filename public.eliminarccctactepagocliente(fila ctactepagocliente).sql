CREATE OR REPLACE FUNCTION public.eliminarccctactepagocliente(fila ctactepagocliente)
 RETURNS ctactepagocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactepagoclientecc:= current_timestamp;
    delete from sincro.ctactepagocliente WHERE idpago= fila.idpago AND idcentropago= fila.idcentropago AND TRUE;
    RETURN fila;
    END;
    $function$
