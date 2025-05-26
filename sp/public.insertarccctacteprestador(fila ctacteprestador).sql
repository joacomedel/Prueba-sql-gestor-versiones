CREATE OR REPLACE FUNCTION public.insertarccctacteprestador(fila ctacteprestador)
 RETURNS ctacteprestador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctacteprestadorcc:= current_timestamp;
    UPDATE sincro.ctacteprestador SET ctacteprestadorcc= fila.ctacteprestadorcc, idctacte= fila.idctacte, idprestador= fila.idprestador WHERE idprestador= fila.idprestador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctacteprestador(ctacteprestadorcc, idctacte, idprestador) VALUES (fila.ctacteprestadorcc, fila.idctacte, fila.idprestador);
    END IF;
    RETURN fila;
    END;
    $function$
