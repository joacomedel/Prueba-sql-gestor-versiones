CREATE OR REPLACE FUNCTION public.eliminarccordconsulta(fila ordconsulta)
 RETURNS ordconsulta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordconsultacc:= current_timestamp;
    delete from sincro.ordconsulta WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
