CREATE OR REPLACE FUNCTION public.insertarccordenpagocontableestado(fila ordenpagocontableestado)
 RETURNS ordenpagocontableestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontableestadocc:= current_timestamp;
    UPDATE sincro.ordenpagocontableestado SET idcentroordenpagocontable= fila.idcentroordenpagocontable, idcentroordenpagocontableestado= fila.idcentroordenpagocontableestado, idordenpagocontable= fila.idordenpagocontable, idordenpagocontableestado= fila.idordenpagocontableestado, idordenpagocontableestadotipo= fila.idordenpagocontableestadotipo, opcdescripcion= fila.opcdescripcion, opcefechaini= fila.opcefechaini, opceidusuario= fila.opceidusuario, opcfechafin= fila.opcfechafin, ordenpagocontableestadocc= fila.ordenpagocontableestadocc WHERE idordenpagocontableestado= fila.idordenpagocontableestado AND idcentroordenpagocontableestado= fila.idcentroordenpagocontableestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpagocontableestado(idcentroordenpagocontable, idcentroordenpagocontableestado, idordenpagocontable, idordenpagocontableestado, idordenpagocontableestadotipo, opcdescripcion, opcefechaini, opceidusuario, opcfechafin, ordenpagocontableestadocc) VALUES (fila.idcentroordenpagocontable, fila.idcentroordenpagocontableestado, fila.idordenpagocontable, fila.idordenpagocontableestado, fila.idordenpagocontableestadotipo, fila.opcdescripcion, fila.opcefechaini, fila.opceidusuario, fila.opcfechafin, fila.ordenpagocontableestadocc);
    END IF;
    RETURN fila;
    END;
    $function$
