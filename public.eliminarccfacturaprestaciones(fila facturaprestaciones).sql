CREATE OR REPLACE FUNCTION public.eliminarccfacturaprestaciones(fila facturaprestaciones)
 RETURNS facturaprestaciones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaprestacionescc:= current_timestamp;
    delete from sincro.facturaprestaciones WHERE anio= fila.anio AND fidtipoprestacion= fila.fidtipoprestacion AND nroregistro= fila.nroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
