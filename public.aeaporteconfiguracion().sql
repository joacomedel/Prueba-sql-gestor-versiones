CREATE OR REPLACE FUNCTION public.aeaporteconfiguracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaporteconfiguracion(OLD);
        return OLD;
    END;
    $function$
