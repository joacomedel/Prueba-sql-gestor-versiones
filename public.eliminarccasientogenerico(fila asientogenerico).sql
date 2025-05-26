CREATE OR REPLACE FUNCTION public.eliminarccasientogenerico(fila asientogenerico)
 RETURNS asientogenerico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericocc:= current_timestamp;
    delete from sincro.asientogenerico WHERE idasientogenerico= fila.idasientogenerico AND idcentroasientogenerico= fila.idcentroasientogenerico AND TRUE;
    RETURN fila;
    END;
    $function$
