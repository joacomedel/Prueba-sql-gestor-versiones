CREATE OR REPLACE FUNCTION public.eliminarcchistoamuc(fila histoamuc)
 RETURNS histoamuc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.histoamuccc:= current_timestamp;
    delete from sincro.histoamuc WHERE fechaini= fila.fechaini AND idhistoamuc= fila.idhistoamuc AND TRUE;
    RETURN fila;
    END;
    $function$
