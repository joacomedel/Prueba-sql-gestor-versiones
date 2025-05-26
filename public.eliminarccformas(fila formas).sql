CREATE OR REPLACE FUNCTION public.eliminarccformas(fila formas)
 RETURNS formas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.formascc:= current_timestamp;
    delete from sincro.formas WHERE idformas= fila.idformas AND TRUE;
    RETURN fila;
    END;
    $function$
