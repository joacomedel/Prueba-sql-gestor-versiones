CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientedeuda_ext(fila cuentacorrientedeuda_ext)
 RETURNS cuentacorrientedeuda_ext
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeuda_extcc:= current_timestamp;
    UPDATE sincro.cuentacorrientedeuda_ext SET ccdborradologico= fila.ccdborradologico, ccdcreacion= fila.ccdcreacion, ccdmodificacion= fila.ccdmodificacion, cuentacorrientedeuda_extcc= fila.cuentacorrientedeuda_extcc, idcentrodeuda= fila.idcentrodeuda, idcuentacorrienteconceptotipo= fila.idcuentacorrienteconceptotipo, iddeuda= fila.iddeuda WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientedeuda_ext(ccdborradologico, ccdcreacion, ccdmodificacion, cuentacorrientedeuda_extcc, idcentrodeuda, idcuentacorrienteconceptotipo, iddeuda) VALUES (fila.ccdborradologico, fila.ccdcreacion, fila.ccdmodificacion, fila.cuentacorrientedeuda_extcc, fila.idcentrodeuda, fila.idcuentacorrienteconceptotipo, fila.iddeuda);
    END IF;
    RETURN fila;
    END;
    $function$
