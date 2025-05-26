CREATE OR REPLACE FUNCTION public.eliminarccprofesional(fila profesional)
 RETURNS profesional
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.profesionalcc:= current_timestamp;
    delete from sincro.profesional WHERE idprestador= fila.idprestador AND TRUE;
    RETURN fila;
    END;
    $function$
