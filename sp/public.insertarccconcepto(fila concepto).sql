CREATE OR REPLACE FUNCTION public.insertarccconcepto(fila concepto)
 RETURNS concepto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.conceptocc:= current_timestamp;
    UPDATE sincro.concepto SET ano= fila.ano, conceptocc= fila.conceptocc, idconcepto= fila.idconcepto, idlaboral= fila.idlaboral, importe= fila.importe, imputacion= fila.imputacion, mes= fila.mes, nroliquidacion= fila.nroliquidacion WHERE idconcepto= fila.idconcepto AND idlaboral= fila.idlaboral AND nroliquidacion= fila.nroliquidacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.concepto(ano, conceptocc, idconcepto, idlaboral, importe, imputacion, mes, nroliquidacion) VALUES (fila.ano, fila.conceptocc, fila.idconcepto, fila.idlaboral, fila.importe, fila.imputacion, fila.mes, fila.nroliquidacion);
    END IF;
    RETURN fila;
    END;
    $function$
