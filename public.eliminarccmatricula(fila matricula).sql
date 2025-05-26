CREATE OR REPLACE FUNCTION public.eliminarccmatricula(fila matricula)
 RETURNS matricula
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.matriculacc:= current_timestamp;
    delete from sincro.matricula WHERE mespecialidad= fila.mespecialidad AND nromatricula= fila.nromatricula AND malcance= fila.malcance AND TRUE;
    RETURN fila;
    END;
    $function$
