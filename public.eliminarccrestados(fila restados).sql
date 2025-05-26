CREATE OR REPLACE FUNCTION public.eliminarccrestados(fila restados)
 RETURNS restados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.restadoscc:= current_timestamp;
    delete from sincro.restados WHERE anio= fila.anio AND idcambioestado= fila.idcambioestado AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    RETURN fila;
    END;
    $function$
