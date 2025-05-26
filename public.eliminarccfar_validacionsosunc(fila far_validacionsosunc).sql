CREATE OR REPLACE FUNCTION public.eliminarccfar_validacionsosunc(fila far_validacionsosunc)
 RETURNS far_validacionsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionsosunccc:= current_timestamp;
    delete from sincro.far_validacionsosunc WHERE idvalidacionsosunc= fila.idvalidacionsosunc AND idcentro= fila.idcentro AND TRUE;
    RETURN fila;
    END;
    $function$
