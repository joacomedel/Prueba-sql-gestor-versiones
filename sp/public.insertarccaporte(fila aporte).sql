CREATE OR REPLACE FUNCTION public.insertarccaporte(fila aporte)
 RETURNS aporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportecc:= current_timestamp;
    UPDATE sincro.aporte SET nrocuentac= fila.nrocuentac, idtipoliquidacion= fila.idtipoliquidacion, idformapagotipos= fila.idformapagotipos, importe= fila.importe, automatica= fila.automatica, aportecc= fila.aportecc, ano= fila.ano, idcargo= fila.idcargo, idresolbe= fila.idresolbe, nroliquidacion= fila.nroliquidacion, idrecibo= fila.idrecibo, fechaingreso= fila.fechaingreso, idcentroregionaluso= fila.idcentroregionaluso, idlaboral= fila.idlaboral, idcertpers= fila.idcertpers, mes= fila.mes, idaporte= fila.idaporte, idlic= fila.idlic WHERE idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aporte(nrocuentac, idtipoliquidacion, idformapagotipos, importe, automatica, aportecc, ano, idcargo, idresolbe, nroliquidacion, idrecibo, fechaingreso, idcentroregionaluso, idlaboral, idcertpers, mes, idaporte, idlic) VALUES (fila.nrocuentac, fila.idtipoliquidacion, fila.idformapagotipos, fila.importe, fila.automatica, fila.aportecc, fila.ano, fila.idcargo, fila.idresolbe, fila.nroliquidacion, fila.idrecibo, fila.fechaingreso, fila.idcentroregionaluso, fila.idlaboral, fila.idcertpers, fila.mes, fila.idaporte, fila.idlic);
    END IF;
    RETURN fila;
    END;
    $function$
