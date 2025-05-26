CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientedeudapagocompensacion(fila cuentacorrientedeudapagocompensacion)
 RETURNS cuentacorrientedeudapagocompensacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagocompensacioncc:= current_timestamp;
    UPDATE sincro.cuentacorrientedeudapagocompensacion SET ccdpcfechamovimiento= fila.ccdpcfechamovimiento, cuentacorrientedeudapagocompensacioncc= fila.cuentacorrientedeudapagocompensacioncc, idcentrodeudagenerada= fila.idcentrodeudagenerada, idcentrodeudaoriginal= fila.idcentrodeudaoriginal, idcentropagogenerada= fila.idcentropagogenerada, idcentropagooriginal= fila.idcentropagooriginal, iddeudagenerada= fila.iddeudagenerada, iddeudaoriginal= fila.iddeudaoriginal, idpagogenerada= fila.idpagogenerada, idpagooriginal= fila.idpagooriginal WHERE idcentropagooriginal= fila.idcentropagooriginal AND idcentrodeudagenerada= fila.idcentrodeudagenerada AND iddeudagenerada= fila.iddeudagenerada AND idpagogenerada= fila.idpagogenerada AND idcentrodeudaoriginal= fila.idcentrodeudaoriginal AND iddeudaoriginal= fila.iddeudaoriginal AND idpagooriginal= fila.idpagooriginal AND idcentropagogenerada= fila.idcentropagogenerada AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientedeudapagocompensacion(ccdpcfechamovimiento, cuentacorrientedeudapagocompensacioncc, idcentrodeudagenerada, idcentrodeudaoriginal, idcentropagogenerada, idcentropagooriginal, iddeudagenerada, iddeudaoriginal, idpagogenerada, idpagooriginal) VALUES (fila.ccdpcfechamovimiento, fila.cuentacorrientedeudapagocompensacioncc, fila.idcentrodeudagenerada, fila.idcentrodeudaoriginal, fila.idcentropagogenerada, fila.idcentropagooriginal, fila.iddeudagenerada, fila.iddeudaoriginal, fila.idpagogenerada, fila.idpagooriginal);
    END IF;
    RETURN fila;
    END;
    $function$
