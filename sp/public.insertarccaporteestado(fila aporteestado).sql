CREATE OR REPLACE FUNCTION public.insertarccaporteestado(fila aporteestado)
 RETURNS aporteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteestadocc:= current_timestamp;
    UPDATE sincro.aporteestado SET aefechafin= fila.aefechafin, aefechainicio= fila.aefechainicio, aeidusuario= fila.aeidusuario, aeobservacion= fila.aeobservacion, aporteestadocc= fila.aporteestadocc, idaporte= fila.idaporte, idaporteestado= fila.idaporteestado, idcentroaporteestado= fila.idcentroaporteestado, idcentroregionaluso= fila.idcentroregionaluso, idestadotipo= fila.idestadotipo WHERE idaporteestado= fila.idaporteestado AND idcentroaporteestado= fila.idcentroaporteestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aporteestado(aefechafin, aefechainicio, aeidusuario, aeobservacion, aporteestadocc, idaporte, idaporteestado, idcentroaporteestado, idcentroregionaluso, idestadotipo) VALUES (fila.aefechafin, fila.aefechainicio, fila.aeidusuario, fila.aeobservacion, fila.aporteestadocc, fila.idaporte, fila.idaporteestado, fila.idcentroaporteestado, fila.idcentroregionaluso, fila.idestadotipo);
    END IF;
    RETURN fila;
    END;
    $function$
