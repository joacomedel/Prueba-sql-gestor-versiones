CREATE OR REPLACE FUNCTION public.eliminarccfar_estado_validador(fila far_estado_validador)
 RETURNS far_estado_validador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_estado_validadorcc:= current_timestamp;
    delete from sincro.far_estado_validador WHERE idestadovalidador= fila.idestadovalidador AND idcentro= fila.idcentro AND TRUE;
    RETURN fila;
    END;
    $function$
