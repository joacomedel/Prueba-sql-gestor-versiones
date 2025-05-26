CREATE OR REPLACE FUNCTION public.insertarccctacteadherenteestado(fila ctacteadherenteestado)
 RETURNS ctacteadherenteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctacteadherenteestadocc:= current_timestamp;
    UPDATE sincro.ctacteadherenteestado SET barra= fila.barra, ccaedescripcion= fila.ccaedescripcion, ccaefechainsercion= fila.ccaefechainsercion, ctacteadherenteestadocc= fila.ctacteadherenteestadocc, idaporte= fila.idaporte, idcentroctacteadherenteestado= fila.idcentroctacteadherenteestado, idcentrodeuda= fila.idcentrodeuda, idcentroregionaluso= fila.idcentroregionaluso, idclientectacte= fila.idclientectacte, idctacteadherenteestado= fila.idctacteadherenteestado, iddeuda= fila.iddeuda, importe= fila.importe, nrocliente= fila.nrocliente, saldo= fila.saldo WHERE idctacteadherenteestado= fila.idctacteadherenteestado AND idcentroctacteadherenteestado= fila.idcentroctacteadherenteestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctacteadherenteestado(barra, ccaedescripcion, ccaefechainsercion, ctacteadherenteestadocc, idaporte, idcentroctacteadherenteestado, idcentrodeuda, idcentroregionaluso, idclientectacte, idctacteadherenteestado, iddeuda, importe, nrocliente, saldo) VALUES (fila.barra, fila.ccaedescripcion, fila.ccaefechainsercion, fila.ctacteadherenteestadocc, fila.idaporte, fila.idcentroctacteadherenteestado, fila.idcentrodeuda, fila.idcentroregionaluso, fila.idclientectacte, fila.idctacteadherenteestado, fila.iddeuda, fila.importe, fila.nrocliente, fila.saldo);
    END IF;
    RETURN fila;
    END;
    $function$
