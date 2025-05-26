CREATE OR REPLACE FUNCTION public.eliminarccasientogenerico_regenerar(fila asientogenerico_regenerar)
 RETURNS asientogenerico_regenerar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenerico_regenerarcc:= current_timestamp;
    delete from sincro.asientogenerico_regenerar WHERE agridcentro= fila.agridcentro AND idagr= fila.idagr AND TRUE;
    RETURN fila;
    END;
    $function$
