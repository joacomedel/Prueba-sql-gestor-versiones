CREATE OR REPLACE FUNCTION public.eliminarcciteminformacion(fila iteminformacion)
 RETURNS iteminformacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.iteminformacioncc:= current_timestamp;
    delete from sincro.iteminformacion WHERE centro= fila.centro AND iditem= fila.iditem AND TRUE;
    RETURN fila;
    END;
    $function$
