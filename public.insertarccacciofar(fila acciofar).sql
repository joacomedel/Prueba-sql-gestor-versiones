CREATE OR REPLACE FUNCTION public.insertarccacciofar(fila acciofar)
 RETURNS acciofar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.acciofarcc:= current_timestamp;
    UPDATE sincro.acciofar SET acciofarcc= fila.acciofarcc, afdescripcion= fila.afdescripcion, idacciofar= fila.idacciofar WHERE idacciofar= fila.idacciofar AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.acciofar(acciofarcc, afdescripcion, idacciofar) VALUES (fila.acciofarcc, fila.afdescripcion, fila.idacciofar);
    END IF;
    RETURN fila;
    END;
    $function$
