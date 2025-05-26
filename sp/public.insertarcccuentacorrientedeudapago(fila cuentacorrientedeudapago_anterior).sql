CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientedeudapago(fila cuentacorrientedeudapago_anterior)
 RETURNS cuentacorrientedeudapago_anterior
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagocc:= current_timestamp;
    UPDATE sincro.cuentacorrientedeudapago SET cuentacorrientedeudapagocc= fila.cuentacorrientedeudapagocc, fechamovimientoimputacion= fila.fechamovimientoimputacion, idcentrodeuda= fila.idcentrodeuda, idcentropago= fila.idcentropago, iddeuda= fila.iddeuda, idpago= fila.idpago WHERE idcentrodeuda= fila.idcentrodeuda AND iddeuda= fila.iddeuda AND idpago= fila.idpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientedeudapago(cuentacorrientedeudapagocc, fechamovimientoimputacion, idcentrodeuda, idcentropago, iddeuda, idpago) VALUES (fila.cuentacorrientedeudapagocc, fila.fechamovimientoimputacion, fila.idcentrodeuda, fila.idcentropago, fila.iddeuda, fila.idpago);
    END IF;
    RETURN fila;
    END;
    $function$
