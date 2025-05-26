CREATE OR REPLACE FUNCTION public.eliminarccfar_parametros(fila far_parametros)
 RETURNS far_parametros
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_parametroscc:= current_timestamp;
    delete from sincro.far_parametros WHERE idparametro= fila.idparametro AND TRUE;
    RETURN fila;
    END;
    $function$
