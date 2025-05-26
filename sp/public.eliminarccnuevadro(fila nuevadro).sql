CREATE OR REPLACE FUNCTION public.eliminarccnuevadro(fila nuevadro)
 RETURNS nuevadro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.nuevadrocc:= current_timestamp;
    delete from sincro.nuevadro WHERE idnuevadro= fila.idnuevadro AND TRUE;
    RETURN fila;
    END;
    $function$
