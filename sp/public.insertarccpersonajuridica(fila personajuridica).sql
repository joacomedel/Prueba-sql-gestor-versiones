CREATE OR REPLACE FUNCTION public.insertarccpersonajuridica(fila personajuridica)
 RETURNS personajuridica
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personajuridicacc:= current_timestamp;
    UPDATE sincro.personajuridica SET denominacion= fila.denominacion, idprestador= fila.idprestador, personajuridicacc= fila.personajuridicacc, siglas= fila.siglas, tipopersjuridica= fila.tipopersjuridica WHERE idprestador= fila.idprestador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.personajuridica(denominacion, idprestador, personajuridicacc, siglas, tipopersjuridica) VALUES (fila.denominacion, fila.idprestador, fila.personajuridicacc, fila.siglas, fila.tipopersjuridica);
    END IF;
    RETURN fila;
    END;
    $function$
