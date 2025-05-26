CREATE OR REPLACE FUNCTION public.insertarcccertpersonal(fila certpersonal)
 RETURNS certpersonal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.certpersonalcc:= current_timestamp;
    UPDATE sincro.certpersonal SET cantaport= fila.cantaport, certpersonalcc= fila.certpersonalcc, idcateg= fila.idcateg, idcertpers= fila.idcertpers WHERE idcertpers= fila.idcertpers AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.certpersonal(cantaport, certpersonalcc, idcateg, idcertpers) VALUES (fila.cantaport, fila.certpersonalcc, fila.idcateg, fila.idcertpers);
    END IF;
    RETURN fila;
    END;
    $function$
