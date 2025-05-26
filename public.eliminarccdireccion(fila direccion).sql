CREATE OR REPLACE FUNCTION public.eliminarccdireccion(fila direccion)
 RETURNS direccion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.direccioncc:= current_timestamp;
    delete from sincro.direccion WHERE idcentrodireccion= fila.idcentrodireccion AND iddireccion= fila.iddireccion AND TRUE;
    RETURN fila;
    END;
    $function$
