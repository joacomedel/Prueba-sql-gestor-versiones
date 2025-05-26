CREATE OR REPLACE FUNCTION public.insertarccpagoscuentacorriente(fila pagoscuentacorriente)
 RETURNS pagoscuentacorriente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoscuentacorrientecc:= current_timestamp;
    UPDATE sincro.pagoscuentacorriente SET idcentrodeuda= fila.idcentrodeuda, idcentropago= fila.idcentropago, idcentroregional= fila.idcentroregional, idmovimiento= fila.idmovimiento, idpagos= fila.idpagos, idpagoscuentacorriente= fila.idpagoscuentacorriente, pagoscuentacorrientecc= fila.pagoscuentacorrientecc WHERE idcentroregional= fila.idcentroregional AND idpagoscuentacorriente= fila.idpagoscuentacorriente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.pagoscuentacorriente(idcentrodeuda, idcentropago, idcentroregional, idmovimiento, idpagos, idpagoscuentacorriente, pagoscuentacorrientecc) VALUES (fila.idcentrodeuda, fila.idcentropago, fila.idcentroregional, fila.idmovimiento, fila.idpagos, fila.idpagoscuentacorriente, fila.pagoscuentacorrientecc);
    END IF;
    RETURN fila;
    END;
    $function$
