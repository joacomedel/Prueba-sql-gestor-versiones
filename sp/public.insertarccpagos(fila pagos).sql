CREATE OR REPLACE FUNCTION public.insertarccpagos(fila pagos)
 RETURNS pagos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoscc:= current_timestamp;
    UPDATE sincro.pagos SET centro= fila.centro, idbanco= fila.idbanco, idcentroregional= fila.idcentroregional, idformapagotipos= fila.idformapagotipos, idlocalidad= fila.idlocalidad, idpagos= fila.idpagos, idpagostipos= fila.idpagostipos, idprovincia= fila.idprovincia, idrecibo= fila.idrecibo, nrocuentabanco= fila.nrocuentabanco, nrocuentac= fila.nrocuentac, nrooperacion= fila.nrooperacion, pagoscc= fila.pagoscc, pconcepto= fila.pconcepto, pfechaemision= fila.pfechaemision, pfechaingreso= fila.pfechaingreso WHERE centro= fila.centro AND idpagos= fila.idpagos AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.pagos(centro, idbanco, idcentroregional, idformapagotipos, idlocalidad, idpagos, idpagostipos, idprovincia, idrecibo, nrocuentabanco, nrocuentac, nrooperacion, pagoscc, pconcepto, pfechaemision, pfechaingreso) VALUES (fila.centro, fila.idbanco, fila.idcentroregional, fila.idformapagotipos, fila.idlocalidad, fila.idpagos, fila.idpagostipos, fila.idprovincia, fila.idrecibo, fila.nrocuentabanco, fila.nrocuentac, fila.nrooperacion, fila.pagoscc, fila.pconcepto, fila.pfechaemision, fila.pfechaingreso);
    END IF;
    RETURN fila;
    END;
    $function$
