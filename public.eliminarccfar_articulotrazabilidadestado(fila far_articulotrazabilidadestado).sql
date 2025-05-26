CREATE OR REPLACE FUNCTION public.eliminarccfar_articulotrazabilidadestado(fila far_articulotrazabilidadestado)
 RETURNS far_articulotrazabilidadestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulotrazabilidadestadocc:= current_timestamp;
    delete from sincro.far_articulotrazabilidadestado WHERE idcentroarticulotrazaestado= fila.idcentroarticulotrazaestado AND idarticulotrazaestado= fila.idarticulotrazaestado AND TRUE;
    RETURN fila;
    END;
    $function$
