CREATE OR REPLACE FUNCTION public.insertarccctactedeudacliente_ext(fila ctactedeudacliente_ext)
 RETURNS ctactedeudacliente_ext
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudacliente_extcc:= current_timestamp;
    UPDATE sincro.ctactedeudacliente_ext SET ccdcborradologico= fila.ccdcborradologico, ccdccreacion= fila.ccdccreacion, ccdcmodificacion= fila.ccdcmodificacion, ctactedeudacliente_extcc= fila.ctactedeudacliente_extcc, idcentrodeuda= fila.idcentrodeuda, idconcepto= fila.idconcepto, idcuentacorrienteconceptotipo= fila.idcuentacorrienteconceptotipo, iddeuda= fila.iddeuda WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctactedeudacliente_ext(ccdcborradologico, ccdccreacion, ccdcmodificacion, ctactedeudacliente_extcc, idcentrodeuda, idconcepto, idcuentacorrienteconceptotipo, iddeuda) VALUES (fila.ccdcborradologico, fila.ccdccreacion, fila.ccdcmodificacion, fila.ctactedeudacliente_extcc, fila.idcentrodeuda, fila.idconcepto, fila.idcuentacorrienteconceptotipo, fila.iddeuda);
    END IF;
    RETURN fila;
    END;
    $function$
