CREATE OR REPLACE FUNCTION public.eliminarccaportejubpen(fila aportejubpen)
 RETURNS aportejubpen
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportejubpencc:= current_timestamp;
    delete from sincro.aportejubpen WHERE anio= fila.anio AND idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
