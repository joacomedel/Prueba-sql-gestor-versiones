CREATE OR REPLACE FUNCTION public.insertarccprestadorconvenio(fila prestadorconvenio)
 RETURNS prestadorconvenio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorconveniocc:= current_timestamp;
    UPDATE sincro.prestadorconvenio SET idconvenio= fila.idconvenio, idprestador= fila.idprestador, prestadorconveniocc= fila.prestadorconveniocc WHERE idconvenio= fila.idconvenio AND idprestador= fila.idprestador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestadorconvenio(idconvenio, idprestador, prestadorconveniocc) VALUES (fila.idconvenio, fila.idprestador, fila.prestadorconveniocc);
    END IF;
    RETURN fila;
    END;
    $function$
