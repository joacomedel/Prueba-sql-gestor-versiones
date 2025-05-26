CREATE OR REPLACE FUNCTION public.insertarccordenrecibo_vinculada(fila ordenrecibo_vinculada)
 RETURNS ordenrecibo_vinculada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenrecibo_vinculadacc:= current_timestamp;
    UPDATE sincro.ordenrecibo_vinculada SET idcentroordenrecibovinculada= fila.idcentroordenrecibovinculada, idordenrecibovinculada= fila.idordenrecibovinculada, ordenrecibo_vinculadacc= fila.ordenrecibo_vinculadacc, orvcentroorigen= fila.orvcentroorigen, orvcentrovinculado= fila.orvcentrovinculado, orvfechaingreso= fila.orvfechaingreso, orvidreciboorigen= fila.orvidreciboorigen, orvidrecibovinculado= fila.orvidrecibovinculado, orvnroordenorigen= fila.orvnroordenorigen, orvnroordenvinculado= fila.orvnroordenvinculado WHERE idordenrecibovinculada= fila.idordenrecibovinculada AND idcentroordenrecibovinculada= fila.idcentroordenrecibovinculada AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenrecibo_vinculada(idcentroordenrecibovinculada, idordenrecibovinculada, ordenrecibo_vinculadacc, orvcentroorigen, orvcentrovinculado, orvfechaingreso, orvidreciboorigen, orvidrecibovinculado, orvnroordenorigen, orvnroordenvinculado) VALUES (fila.idcentroordenrecibovinculada, fila.idordenrecibovinculada, fila.ordenrecibo_vinculadacc, fila.orvcentroorigen, fila.orvcentrovinculado, fila.orvfechaingreso, fila.orvidreciboorigen, fila.orvidrecibovinculado, fila.orvnroordenorigen, fila.orvnroordenvinculado);
    END IF;
    RETURN fila;
    END;
    $function$
