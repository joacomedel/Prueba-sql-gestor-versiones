CREATE OR REPLACE FUNCTION public.eliminarccfar_remitofactura(fila far_remitofactura)
 RETURNS far_remitofactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitofacturacc:= current_timestamp;
    delete from sincro.far_remitofactura WHERE anio= fila.anio AND centro= fila.centro AND idremito= fila.idremito AND nroregistro= fila.nroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
