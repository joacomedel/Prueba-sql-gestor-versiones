CREATE OR REPLACE FUNCTION public.eliminarccordvalorizada(fila ordvalorizada)
 RETURNS ordvalorizada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordvalorizadacc:= current_timestamp;
    delete from sincro.ordvalorizada WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
