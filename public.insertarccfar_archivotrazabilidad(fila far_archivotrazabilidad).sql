CREATE OR REPLACE FUNCTION public.insertarccfar_archivotrazabilidad(fila far_archivotrazabilidad)
 RETURNS far_archivotrazabilidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_archivotrazabilidadcc:= current_timestamp;
    UPDATE sincro.far_archivotrazabilidad SET idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad, atracontenidoenvio= fila.atracontenidoenvio, idusuario= fila.idusuario, atfechageneracion= fila.atfechageneracion, atratipoarchivo= fila.atratipoarchivo, atracontenidorespuesta= fila.atracontenidorespuesta, far_archivotrazabilidadcc= fila.far_archivotrazabilidadcc, idarchivostrazabilidad= fila.idarchivostrazabilidad WHERE idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad AND idarchivostrazabilidad= fila.idarchivostrazabilidad AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_archivotrazabilidad(idcentroarchivostrazabilidad, atracontenidoenvio, idusuario, atfechageneracion, atratipoarchivo, atracontenidorespuesta, far_archivotrazabilidadcc, idarchivostrazabilidad) VALUES (fila.idcentroarchivostrazabilidad, fila.atracontenidoenvio, fila.idusuario, fila.atfechageneracion, fila.atratipoarchivo, fila.atracontenidorespuesta, fila.far_archivotrazabilidadcc, fila.idarchivostrazabilidad);
    END IF;
    RETURN fila;
    END;
    $function$
