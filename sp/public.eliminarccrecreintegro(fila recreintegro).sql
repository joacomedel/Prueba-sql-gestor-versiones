CREATE OR REPLACE FUNCTION public.eliminarccrecreintegro(fila recreintegro)
 RETURNS recreintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recreintegrocc:= current_timestamp;
    delete from sincro.recreintegro WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
