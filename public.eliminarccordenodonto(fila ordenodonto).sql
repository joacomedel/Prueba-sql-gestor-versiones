CREATE OR REPLACE FUNCTION public.eliminarccordenodonto(fila ordenodonto)
 RETURNS ordenodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenodontocc:= current_timestamp;
    delete from sincro.ordenodonto WHERE centro= fila.centro AND iditem= fila.iditem AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
