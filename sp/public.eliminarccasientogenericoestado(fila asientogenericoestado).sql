CREATE OR REPLACE FUNCTION public.eliminarccasientogenericoestado(fila asientogenericoestado)
 RETURNS asientogenericoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericoestadocc:= current_timestamp;
    delete from sincro.asientogenericoestado WHERE idasientogenericoestado= fila.idasientogenericoestado AND idcentroasientogenericoestado= fila.idcentroasientogenericoestado AND TRUE;
    RETURN fila;
    END;
    $function$
