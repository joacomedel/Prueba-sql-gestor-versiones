CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventa(fila far_ordenventa)
 RETURNS far_ordenventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventacc:= current_timestamp;
    delete from sincro.far_ordenventa WHERE idcentroordenventa= fila.idcentroordenventa AND idordenventa= fila.idordenventa AND TRUE;
    RETURN fila;
    END;
    $function$
