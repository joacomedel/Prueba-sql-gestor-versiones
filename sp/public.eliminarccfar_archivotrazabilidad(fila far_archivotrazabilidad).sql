CREATE OR REPLACE FUNCTION public.eliminarccfar_archivotrazabilidad(fila far_archivotrazabilidad)
 RETURNS far_archivotrazabilidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_archivotrazabilidadcc:= current_timestamp;
    delete from sincro.far_archivotrazabilidad WHERE idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad AND idarchivostrazabilidad= fila.idarchivostrazabilidad AND TRUE;
    RETURN fila;
    END;
    $function$
