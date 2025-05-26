CREATE OR REPLACE FUNCTION public.eliminarccusuariopersona(fila usuariopersona)
 RETURNS usuariopersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuariopersonacc:= current_timestamp;
    delete from sincro.usuariopersona WHERE idcentroregional= fila.idcentroregional AND idusuariopersona= fila.idusuariopersona AND TRUE;
    RETURN fila;
    END;
    $function$
