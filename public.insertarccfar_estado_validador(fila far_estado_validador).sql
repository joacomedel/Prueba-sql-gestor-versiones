CREATE OR REPLACE FUNCTION public.insertarccfar_estado_validador(fila far_estado_validador)
 RETURNS far_estado_validador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_estado_validadorcc:= current_timestamp;
    UPDATE sincro.far_estado_validador SET far_estado_validadorcc= fila.far_estado_validadorcc, fevactivo= fila.fevactivo, fevfechafin= fila.fevfechafin, fevfechainicio= fila.fevfechainicio, idcentro= fila.idcentro, idestadovalidador= fila.idestadovalidador, idobrasocial= fila.idobrasocial, idusuario= fila.idusuario WHERE idestadovalidador= fila.idestadovalidador AND idcentro= fila.idcentro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_estado_validador(far_estado_validadorcc, fevactivo, fevfechafin, fevfechainicio, idcentro, idestadovalidador, idobrasocial, idusuario) VALUES (fila.far_estado_validadorcc, fila.fevactivo, fila.fevfechafin, fila.fevfechainicio, fila.idcentro, fila.idestadovalidador, fila.idobrasocial, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
