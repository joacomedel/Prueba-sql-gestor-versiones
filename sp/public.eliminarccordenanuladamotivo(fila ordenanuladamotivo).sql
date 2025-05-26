CREATE OR REPLACE FUNCTION public.eliminarccordenanuladamotivo(fila ordenanuladamotivo)
 RETURNS ordenanuladamotivo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenanuladamotivocc:= current_timestamp;
    delete from sincro.ordenanuladamotivo WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
