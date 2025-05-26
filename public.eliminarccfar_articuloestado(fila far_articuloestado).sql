CREATE OR REPLACE FUNCTION public.eliminarccfar_articuloestado(fila far_articuloestado)
 RETURNS far_articuloestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloestadocc:= current_timestamp;
    delete from sincro.far_articuloestado WHERE idarticuloestado= fila.idarticuloestado AND idcentroarticuloestado= fila.idcentroarticuloestado AND TRUE;
    RETURN fila;
    END;
    $function$
