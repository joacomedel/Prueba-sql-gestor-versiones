CREATE OR REPLACE FUNCTION public.insertarccsolicitudauditoria_archivos(fila solicitudauditoria_archivos)
 RETURNS solicitudauditoria_archivos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoria_archivoscc:= current_timestamp;
    UPDATE sincro.solicitudauditoria_archivos SET idcentrogestionarchivos= fila.idcentrogestionarchivos, idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria, idcentrosolicitudauditoriaarchivo= fila.idcentrosolicitudauditoriaarchivo, idgestionarchivos= fila.idgestionarchivos, idsolicitudauditoria= fila.idsolicitudauditoria, idsolicitudauditoriaarchivo= fila.idsolicitudauditoriaarchivo, solicitudauditoria_archivoscc= fila.solicitudauditoria_archivoscc WHERE idcentrosolicitudauditoriaarchivo= fila.idcentrosolicitudauditoriaarchivo AND idsolicitudauditoriaarchivo= fila.idsolicitudauditoriaarchivo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.solicitudauditoria_archivos(idcentrogestionarchivos, idcentrosolicitudauditoria, idcentrosolicitudauditoriaarchivo, idgestionarchivos, idsolicitudauditoria, idsolicitudauditoriaarchivo, solicitudauditoria_archivoscc) VALUES (fila.idcentrogestionarchivos, fila.idcentrosolicitudauditoria, fila.idcentrosolicitudauditoriaarchivo, fila.idgestionarchivos, fila.idsolicitudauditoria, fila.idsolicitudauditoriaarchivo, fila.solicitudauditoria_archivoscc);
    END IF;
    RETURN fila;
    END;
    $function$
