CREATE OR REPLACE FUNCTION public.eliminarccconsumorecetarioreciprocidad(fila consumorecetarioreciprocidad)
 RETURNS consumorecetarioreciprocidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumorecetarioreciprocidadcc:= current_timestamp;
    delete from sincro.consumorecetarioreciprocidad WHERE TRUE;
    RETURN fila;
    END;
    $function$
