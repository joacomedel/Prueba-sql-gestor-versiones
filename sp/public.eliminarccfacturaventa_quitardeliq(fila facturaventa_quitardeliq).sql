CREATE OR REPLACE FUNCTION public.eliminarccfacturaventa_quitardeliq(fila facturaventa_quitardeliq)
 RETURNS facturaventa_quitardeliq
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventa_quitardeliqcc:= current_timestamp;
    delete from sincro.facturaventa_quitardeliq WHERE idcentrofacturaventaquitardeliq= fila.idcentrofacturaventaquitardeliq AND idfacturaventaquitardeliq= fila.idfacturaventaquitardeliq AND TRUE;
    RETURN fila;
    END;
    $function$
