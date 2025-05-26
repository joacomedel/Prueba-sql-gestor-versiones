CREATE OR REPLACE FUNCTION public.eliminarccreclibrocon(fila reclibrocon)
 RETURNS reclibrocon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reclibroconcc:= current_timestamp;
    delete from sincro.reclibrocon WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
