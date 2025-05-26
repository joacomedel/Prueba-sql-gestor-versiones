CREATE OR REPLACE FUNCTION public.insertarccmapeoprestadores(fila mapeoprestadores)
 RETURNS mapeoprestadores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mapeoprestadorescc:= current_timestamp;
    UPDATE sincro.mapeoprestadores SET update= fila.update, mapeoprestadorescc= fila.mapeoprestadorescc, idprestadormultivac= fila.idprestadormultivac, cuitmultivac= fila.cuitmultivac, idprestadorsiges= fila.idprestadorsiges, detallemultivac= fila.detallemultivac, fechaupdate= fila.fechaupdate WHERE idprestadorsiges= fila.idprestadorsiges AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.mapeoprestadores(update, mapeoprestadorescc, idprestadormultivac, cuitmultivac, idprestadorsiges, detallemultivac, fechaupdate) VALUES (fila.update, fila.mapeoprestadorescc, fila.idprestadormultivac, fila.cuitmultivac, fila.idprestadorsiges, fila.detallemultivac, fila.fechaupdate);
    END IF;
    RETURN fila;
    END;
    $function$
