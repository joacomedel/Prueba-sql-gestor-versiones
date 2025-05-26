CREATE OR REPLACE FUNCTION public.insertarccctactedeudapagocliente(fila ctactedeudapagocliente)
 RETURNS ctactedeudapagocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudapagoclientecc:= current_timestamp;
    UPDATE sincro.ctactedeudapagocliente SET ctactedeudapagoclientecc= fila.ctactedeudapagoclientecc, fechamovimientoimputacion= fila.fechamovimientoimputacion, idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente, idcentrodeuda= fila.idcentrodeuda, idcentropago= fila.idcentropago, idctactedeudapagocliente= fila.idctactedeudapagocliente, iddeuda= fila.iddeuda, idimputacion= fila.idimputacion, idpago= fila.idpago, idusuario= fila.idusuario, importeimp= fila.importeimp WHERE idctactedeudapagocliente= fila.idctactedeudapagocliente AND idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctactedeudapagocliente(ctactedeudapagoclientecc, fechamovimientoimputacion, idcentroctactedeudapagocliente, idcentrodeuda, idcentropago, idctactedeudapagocliente, iddeuda, idimputacion, idpago, idusuario, importeimp) VALUES (fila.ctactedeudapagoclientecc, fila.fechamovimientoimputacion, fila.idcentroctactedeudapagocliente, fila.idcentrodeuda, fila.idcentropago, fila.idctactedeudapagocliente, fila.iddeuda, fila.idimputacion, fila.idpago, fila.idusuario, fila.importeimp);
    END IF;
    RETURN fila;
    END;
    $function$
