CREATE OR REPLACE FUNCTION public.insertarccpase(fila pase)
 RETURNS pase
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pasecc:= current_timestamp;
    UPDATE sincro.pase SET idcentrodocumento= fila.idcentrodocumento, idcentropase= fila.idcentropase, iddocumento= fila.iddocumento, idpase= fila.idpase, idpersonadestino= fila.idpersonadestino, idpersonaorigen= fila.idpersonaorigen, idsectordestino= fila.idsectordestino, idsectororigen= fila.idsectororigen, pacantfolios= fila.pacantfolios, pafechaenvio= fila.pafechaenvio, pafecharecepcion= fila.pafecharecepcion, pafolio= fila.pafolio, palibro= fila.palibro, pamotivo= fila.pamotivo, pasecc= fila.pasecc, personal= fila.personal WHERE idpase= fila.idpase AND idcentropase= fila.idcentropase AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.pase(idcentrodocumento, idcentropase, iddocumento, idpase, idpersonadestino, idpersonaorigen, idsectordestino, idsectororigen, pacantfolios, pafechaenvio, pafecharecepcion, pafolio, palibro, pamotivo, pasecc, personal) VALUES (fila.idcentrodocumento, fila.idcentropase, fila.iddocumento, fila.idpase, fila.idpersonadestino, fila.idpersonaorigen, fila.idsectordestino, fila.idsectororigen, fila.pacantfolios, fila.pafechaenvio, fila.pafecharecepcion, fila.pafolio, fila.palibro, fila.pamotivo, fila.pasecc, fila.personal);
    END IF;
    RETURN fila;
    END;
    $function$
