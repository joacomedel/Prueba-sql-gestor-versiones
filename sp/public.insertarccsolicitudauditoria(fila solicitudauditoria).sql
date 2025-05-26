CREATE OR REPLACE FUNCTION public.insertarccsolicitudauditoria(fila solicitudauditoria)
 RETURNS solicitudauditoria
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriacc:= current_timestamp;
    UPDATE sincro.solicitudauditoria SET idcentro= fila.idcentro, idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria, idprestador= fila.idprestador, idsolicitudauditoria= fila.idsolicitudauditoria, nrodoc= fila.nrodoc, nrorecetario= fila.nrorecetario, sadiagnostico= fila.sadiagnostico, safechaingreso= fila.safechaingreso, saidusuario= fila.saidusuario, solicitudauditoriacc= fila.solicitudauditoriacc, tipodoc= fila.tipodoc WHERE idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria AND idsolicitudauditoria= fila.idsolicitudauditoria AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.solicitudauditoria(idcentro, idcentrosolicitudauditoria, idprestador, idsolicitudauditoria, nrodoc, nrorecetario, sadiagnostico, safechaingreso, saidusuario, solicitudauditoriacc, tipodoc) VALUES (fila.idcentro, fila.idcentrosolicitudauditoria, fila.idprestador, fila.idsolicitudauditoria, fila.nrodoc, fila.nrorecetario, fila.sadiagnostico, fila.safechaingreso, fila.saidusuario, fila.solicitudauditoriacc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
