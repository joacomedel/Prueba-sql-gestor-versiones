CREATE OR REPLACE FUNCTION public.insertarccsolicitudauditoriaestado(fila solicitudauditoriaestado)
 RETURNS solicitudauditoriaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriaestadocc:= current_timestamp;
    UPDATE sincro.solicitudauditoriaestado SET idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria, idcentrosolicitudauditoriaestado= fila.idcentrosolicitudauditoriaestado, idsolicitudauditoria= fila.idsolicitudauditoria, idsolicitudauditoriaestado= fila.idsolicitudauditoriaestado, idsolicitudauditoriaestadotipo= fila.idsolicitudauditoriaestadotipo, saefechafin= fila.saefechafin, saefechainicio= fila.saefechainicio, saeidusuario= fila.saeidusuario, saeobservacion= fila.saeobservacion, saetdescripcion= fila.saetdescripcion, solicitudauditoriaestadocc= fila.solicitudauditoriaestadocc WHERE idcentrosolicitudauditoriaestado= fila.idcentrosolicitudauditoriaestado AND idsolicitudauditoriaestado= fila.idsolicitudauditoriaestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.solicitudauditoriaestado(idcentrosolicitudauditoria, idcentrosolicitudauditoriaestado, idsolicitudauditoria, idsolicitudauditoriaestado, idsolicitudauditoriaestadotipo, saefechafin, saefechainicio, saeidusuario, saeobservacion, saetdescripcion, solicitudauditoriaestadocc) VALUES (fila.idcentrosolicitudauditoria, fila.idcentrosolicitudauditoriaestado, fila.idsolicitudauditoria, fila.idsolicitudauditoriaestado, fila.idsolicitudauditoriaestadotipo, fila.saefechafin, fila.saefechainicio, fila.saeidusuario, fila.saeobservacion, fila.saetdescripcion, fila.solicitudauditoriaestadocc);
    END IF;
    RETURN fila;
    END;
    $function$
