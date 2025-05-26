CREATE OR REPLACE FUNCTION public.eliminarccsubsidios(fila subsidios)
 RETURNS subsidios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.subsidioscc:= current_timestamp;
    delete from sincro.subsidios WHERE clave= fila.clave AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
