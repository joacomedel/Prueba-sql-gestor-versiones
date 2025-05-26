CREATE OR REPLACE FUNCTION public.eliminarccnotascreditospendientes(fila notascreditospendientes)
 RETURNS notascreditospendientes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.notascreditospendientescc:= current_timestamp;
    delete from sincro.notascreditospendientes WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
