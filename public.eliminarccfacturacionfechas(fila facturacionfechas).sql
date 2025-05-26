CREATE OR REPLACE FUNCTION public.eliminarccfacturacionfechas(fila facturacionfechas)
 RETURNS facturacionfechas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturacionfechascc:= current_timestamp;
    delete from sincro.facturacionfechas WHERE anio= fila.anio AND ffechafin= fila.ffechafin AND ffechaini= fila.ffechaini AND nroregistro= fila.nroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
