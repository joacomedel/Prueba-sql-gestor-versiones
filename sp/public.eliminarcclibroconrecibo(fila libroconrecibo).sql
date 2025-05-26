CREATE OR REPLACE FUNCTION public.eliminarcclibroconrecibo(fila libroconrecibo)
 RETURNS libroconrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.libroconrecibocc:= current_timestamp;
    delete from sincro.libroconrecibo WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
