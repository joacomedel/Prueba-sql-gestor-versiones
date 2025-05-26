CREATE OR REPLACE FUNCTION public.insertarcccompramedicamento(fila compramedicamento)
 RETURNS compramedicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.compramedicamentocc:= current_timestamp;
    UPDATE sincro.compramedicamento SET anio= fila.anio, cmfecha= fila.cmfecha, cmfechavenc= fila.cmfechavenc, compramedicamentocc= fila.compramedicamentocc, idcompramedicamento= fila.idcompramedicamento, idcompramedicamentotipos= fila.idcompramedicamentotipos, idprestador= fila.idprestador, nroregistro= fila.nroregistro WHERE idcompramedicamento= fila.idcompramedicamento AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.compramedicamento(anio, cmfecha, cmfechavenc, compramedicamentocc, idcompramedicamento, idcompramedicamentotipos, idprestador, nroregistro) VALUES (fila.anio, fila.cmfecha, fila.cmfechavenc, fila.compramedicamentocc, fila.idcompramedicamento, fila.idcompramedicamentotipos, fila.idprestador, fila.nroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
