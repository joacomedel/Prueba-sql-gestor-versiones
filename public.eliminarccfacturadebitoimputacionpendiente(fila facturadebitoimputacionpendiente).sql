CREATE OR REPLACE FUNCTION public.eliminarccfacturadebitoimputacionpendiente(fila facturadebitoimputacionpendiente)
 RETURNS facturadebitoimputacionpendiente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturadebitoimputacionpendientecc:= current_timestamp;
    delete from sincro.facturadebitoimputacionpendiente WHERE idfacturadebitoimputacionpendie= fila.idfacturadebitoimputacionpendie AND idcentrofacturadebitoimputacionpendiente= fila.idcentrofacturadebitoimputacionpendiente AND TRUE;
    RETURN fila;
    END;
    $function$
