CREATE OR REPLACE FUNCTION public.eliminarccfar_configura_reporte(fila far_configura_reporte)
 RETURNS far_configura_reporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_configura_reportecc:= current_timestamp;
    delete from sincro.far_configura_reporte WHERE crseparavalidacion= fila.crseparavalidacion AND idobrasocial= fila.idobrasocial AND idtiporeporte= fila.idtiporeporte AND idvalorcajacoseguro= fila.idvalorcajacoseguro AND idvalorcajactacte= fila.idvalorcajactacte AND TRUE;
    RETURN fila;
    END;
    $function$
