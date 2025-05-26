CREATE OR REPLACE FUNCTION public.eliminarccfar_precioarticulohermano(fila far_precioarticulohermano)
 RETURNS far_precioarticulohermano
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulohermanocc:= current_timestamp;
    delete from sincro.far_precioarticulohermano WHERE idarticulokairo= fila.idarticulokairo AND idarticulohermano= fila.idarticulohermano AND idcentroarticulohermano= fila.idcentroarticulohermano AND idcentroarticulokairo= fila.idcentroarticulokairo AND TRUE;
    RETURN fila;
    END;
    $function$
