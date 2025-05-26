CREATE OR REPLACE FUNCTION public.eliminarccconcepto(fila concepto)
 RETURNS concepto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.conceptocc:= current_timestamp;
    delete from sincro.concepto WHERE idconcepto= fila.idconcepto AND idlaboral= fila.idlaboral AND nroliquidacion= fila.nroliquidacion AND TRUE;
    RETURN fila;
    END;
    $function$
