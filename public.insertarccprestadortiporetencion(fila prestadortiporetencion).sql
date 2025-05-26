CREATE OR REPLACE FUNCTION public.insertarccprestadortiporetencion(fila prestadortiporetencion)
 RETURNS prestadortiporetencion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadortiporetencioncc:= current_timestamp;
    UPDATE sincro.prestadortiporetencion SET idprestador= fila.idprestador, idtiporetencion= fila.idtiporetencion, prestadortiporetencioncc= fila.prestadortiporetencioncc WHERE idprestador= fila.idprestador AND idtiporetencion= fila.idtiporetencion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestadortiporetencion(idprestador, idtiporetencion, prestadortiporetencioncc) VALUES (fila.idprestador, fila.idtiporetencion, fila.prestadortiporetencioncc);
    END IF;
    RETURN fila;
    END;
    $function$
