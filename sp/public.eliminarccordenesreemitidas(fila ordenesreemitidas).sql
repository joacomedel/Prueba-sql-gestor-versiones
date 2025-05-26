CREATE OR REPLACE FUNCTION public.eliminarccordenesreemitidas(fila ordenesreemitidas)
 RETURNS ordenesreemitidas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenesreemitidascc:= current_timestamp;
    delete from sincro.ordenesreemitidas WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
