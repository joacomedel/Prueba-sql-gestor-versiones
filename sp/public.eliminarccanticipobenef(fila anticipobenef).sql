CREATE OR REPLACE FUNCTION public.eliminarccanticipobenef(fila anticipobenef)
 RETURNS anticipobenef
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipobenefcc:= current_timestamp;
    delete from sincro.anticipobenef WHERE nrodoc= fila.nrodoc AND barra= fila.barra AND nroanticipo= fila.nroanticipo AND anio= fila.anio AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
