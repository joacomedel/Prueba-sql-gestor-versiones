CREATE OR REPLACE FUNCTION public.eliminarccasientogenericoitem(fila asientogenericoitem)
 RETURNS asientogenericoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericoitemcc:= current_timestamp;
    delete from sincro.asientogenericoitem WHERE idcentroasientogenericoitem= fila.idcentroasientogenericoitem AND idasientogenericoitem= fila.idasientogenericoitem AND TRUE;
    RETURN fila;
    END;
    $function$
