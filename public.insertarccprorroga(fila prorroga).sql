CREATE OR REPLACE FUNCTION public.insertarccprorroga(fila prorroga)
 RETURNS prorroga
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prorrogacc:= current_timestamp;
    UPDATE sincro.prorroga SET certestudio= fila.certestudio, declarajurada= fila.declarajurada, fechaemision= fila.fechaemision, fechavto= fila.fechavto, idcentroregional= fila.idcentroregional, idprorr= fila.idprorr, nrodoc= fila.nrodoc, prorrogacc= fila.prorrogacc, tipodoc= fila.tipodoc, tipoprorr= fila.tipoprorr WHERE idcentroregional= fila.idcentroregional AND idprorr= fila.idprorr AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prorroga(certestudio, declarajurada, fechaemision, fechavto, idcentroregional, idprorr, nrodoc, prorrogacc, tipodoc, tipoprorr) VALUES (fila.certestudio, fila.declarajurada, fila.fechaemision, fila.fechavto, fila.idcentroregional, fila.idprorr, fila.nrodoc, fila.prorrogacc, fila.tipodoc, fila.tipoprorr);
    END IF;
    RETURN fila;
    END;
    $function$
