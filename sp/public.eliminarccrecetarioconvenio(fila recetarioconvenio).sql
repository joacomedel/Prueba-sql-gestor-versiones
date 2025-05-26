CREATE OR REPLACE FUNCTION public.eliminarccrecetarioconvenio(fila recetarioconvenio)
 RETURNS recetarioconvenio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioconveniocc:= current_timestamp;
    delete from sincro.recetarioconvenio WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    RETURN fila;
    END;
    $function$
