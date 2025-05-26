CREATE OR REPLACE FUNCTION public.eliminarccfacturaventacuponestado(fila facturaventacuponestado)
 RETURNS facturaventacuponestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponestadocc:= current_timestamp;
    delete from sincro.facturaventacuponestado WHERE idcentrofacturaventacuponestado= fila.idcentrofacturaventacuponestado AND idfacturaventacuponestado= fila.idfacturaventacuponestado AND TRUE;
    RETURN fila;
    END;
    $function$
