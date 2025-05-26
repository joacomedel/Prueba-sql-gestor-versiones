CREATE OR REPLACE FUNCTION public.eliminarccaportessinfacturas(fila aportessinfacturas)
 RETURNS aportessinfacturas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportessinfacturascc:= current_timestamp;
    delete from sincro.aportessinfacturas WHERE anio= fila.anio AND idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
