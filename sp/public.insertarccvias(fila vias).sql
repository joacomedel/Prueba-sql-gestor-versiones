CREATE OR REPLACE FUNCTION public.insertarccvias(fila vias)
 RETURNS vias
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.viascc:= current_timestamp;
    UPDATE sincro.vias SET idvias= fila.idvias, vdescripcion= fila.vdescripcion, viascc= fila.viascc WHERE idvias= fila.idvias AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.vias(idvias, vdescripcion, viascc) VALUES (fila.idvias, fila.vdescripcion, fila.viascc);
    END IF;
    RETURN fila;
    END;
    $function$
