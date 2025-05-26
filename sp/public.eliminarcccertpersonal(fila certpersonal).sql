CREATE OR REPLACE FUNCTION public.eliminarcccertpersonal(fila certpersonal)
 RETURNS certpersonal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.certpersonalcc:= current_timestamp;
    delete from sincro.certpersonal WHERE idcertpers= fila.idcertpers AND TRUE;
    RETURN fila;
    END;
    $function$
