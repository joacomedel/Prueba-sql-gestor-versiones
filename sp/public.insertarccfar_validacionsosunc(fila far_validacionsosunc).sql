CREATE OR REPLACE FUNCTION public.insertarccfar_validacionsosunc(fila far_validacionsosunc)
 RETURNS far_validacionsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionsosunccc:= current_timestamp;
    UPDATE sincro.far_validacionsosunc SET far_validacionsosunccc= fila.far_validacionsosunccc, fvactivo= fila.fvactivo, fvfechafin= fila.fvfechafin, fvfechainicio= fila.fvfechainicio, idcentro= fila.idcentro, idusuario= fila.idusuario, idvalidacionsosunc= fila.idvalidacionsosunc WHERE idvalidacionsosunc= fila.idvalidacionsosunc AND idcentro= fila.idcentro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_validacionsosunc(far_validacionsosunccc, fvactivo, fvfechafin, fvfechainicio, idcentro, idusuario, idvalidacionsosunc) VALUES (fila.far_validacionsosunccc, fila.fvactivo, fila.fvfechafin, fila.fvfechainicio, fila.idcentro, fila.idusuario, fila.idvalidacionsosunc);
    END IF;
    RETURN fila;
    END;
    $function$
