CREATE OR REPLACE FUNCTION public.eliminarccpagoscuentacorriente(fila pagoscuentacorriente)
 RETURNS pagoscuentacorriente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoscuentacorrientecc:= current_timestamp;
    delete from sincro.pagoscuentacorriente WHERE idcentroregional= fila.idcentroregional AND idpagoscuentacorriente= fila.idpagoscuentacorriente AND TRUE;
    RETURN fila;
    END;
    $function$
