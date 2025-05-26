CREATE OR REPLACE FUNCTION public.eliminarccadmusuariostransaccion(fila admusuariostransaccion)
 RETURNS admusuariostransaccion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admusuariostransaccioncc:= current_timestamp;
    delete from sincro.admusuariostransaccion WHERE idmodulo= fila.idmodulo AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
