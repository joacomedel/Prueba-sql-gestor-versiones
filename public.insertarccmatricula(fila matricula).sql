CREATE OR REPLACE FUNCTION public.insertarccmatricula(fila matricula)
 RETURNS matricula
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.matriculacc:= current_timestamp;
    UPDATE sincro.matricula SET idprestador= fila.idprestador, malcance= fila.malcance, matriculacc= fila.matriculacc, mespecialidad= fila.mespecialidad, nromatricula= fila.nromatricula WHERE mespecialidad= fila.mespecialidad AND nromatricula= fila.nromatricula AND malcance= fila.malcance AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.matricula(idprestador, malcance, matriculacc, mespecialidad, nromatricula) VALUES (fila.idprestador, fila.malcance, fila.matriculacc, fila.mespecialidad, fila.nromatricula);
    END IF;
    RETURN fila;
    END;
    $function$
