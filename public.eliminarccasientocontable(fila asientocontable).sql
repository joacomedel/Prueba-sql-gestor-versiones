CREATE OR REPLACE FUNCTION public.eliminarccasientocontable(fila asientocontable)
 RETURNS asientocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientocontablecc:= current_timestamp;
    delete from sincro.asientocontable WHERE idasientocontable= fila.idasientocontable AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
