CREATE OR REPLACE FUNCTION public.eliminarccitemvalorizada(fila itemvalorizada)
 RETURNS itemvalorizada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemvalorizadacc:= current_timestamp;
    delete from sincro.itemvalorizada WHERE centro= fila.centro AND iditem= fila.iditem AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
