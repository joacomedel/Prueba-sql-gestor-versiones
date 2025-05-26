CREATE OR REPLACE FUNCTION public.aerecafiliacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecafiliacion(OLD);
        return OLD;
    END;
    $function$
