CREATE OR REPLACE FUNCTION public.insertarccfar_articulotrazabilidadestado(fila far_articulotrazabilidadestado)
 RETURNS far_articulotrazabilidadestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulotrazabilidadestadocc:= current_timestamp;
    UPDATE sincro.far_articulotrazabilidadestado SET idarticulotrazabilidadestadotipos= fila.idarticulotrazabilidadestadotipos, idarticulotraza= fila.idarticulotraza, atefechafin= fila.atefechafin, idarticulotrazaestado= fila.idarticulotrazaestado, idcentroarticulotrazaestado= fila.idcentroarticulotrazaestado, far_articulotrazabilidadestadocc= fila.far_articulotrazabilidadestadocc, atefechainicio= fila.atefechainicio, idcentroarticulotraza= fila.idcentroarticulotraza, atedescripcion= fila.atedescripcion WHERE idcentroarticulotrazaestado= fila.idcentroarticulotrazaestado AND idarticulotrazaestado= fila.idarticulotrazaestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articulotrazabilidadestado(idarticulotrazabilidadestadotipos, idarticulotraza, atefechafin, idarticulotrazaestado, idcentroarticulotrazaestado, far_articulotrazabilidadestadocc, atefechainicio, idcentroarticulotraza, atedescripcion) VALUES (fila.idarticulotrazabilidadestadotipos, fila.idarticulotraza, fila.atefechafin, fila.idarticulotrazaestado, fila.idcentroarticulotrazaestado, fila.far_articulotrazabilidadestadocc, fila.atefechainicio, fila.idcentroarticulotraza, fila.atedescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
