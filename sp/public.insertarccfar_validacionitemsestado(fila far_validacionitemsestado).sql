CREATE OR REPLACE FUNCTION public.insertarccfar_validacionitemsestado(fila far_validacionitemsestado)
 RETURNS far_validacionitemsestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionitemsestadocc:= current_timestamp;
    UPDATE sincro.far_validacionitemsestado SET idvalidacionitem= fila.idvalidacionitem, idvalidacionitemsestado= fila.idvalidacionitemsestado, viefechaini= fila.viefechaini, far_validacionitemsestadocc= fila.far_validacionitemsestadocc, viefechafin= fila.viefechafin, idcentrovalidacionitemsestado= fila.idcentrovalidacionitemsestado, idcentrovalidacionitem= fila.idcentrovalidacionitem, idvalidacionitemsestadotipo= fila.idvalidacionitemsestadotipo WHERE idvalidacionitemsestado= fila.idvalidacionitemsestado AND idcentrovalidacionitemsestado= fila.idcentrovalidacionitemsestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_validacionitemsestado(idvalidacionitem, idvalidacionitemsestado, viefechaini, far_validacionitemsestadocc, viefechafin, idcentrovalidacionitemsestado, idcentrovalidacionitem, idvalidacionitemsestadotipo) VALUES (fila.idvalidacionitem, fila.idvalidacionitemsestado, fila.viefechaini, fila.far_validacionitemsestadocc, fila.viefechafin, fila.idcentrovalidacionitemsestado, fila.idcentrovalidacionitem, fila.idvalidacionitemsestadotipo);
    END IF;
    RETURN fila;
    END;
    $function$
