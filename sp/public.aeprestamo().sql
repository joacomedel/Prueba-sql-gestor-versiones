CREATE OR REPLACE FUNCTION public.aeprestamo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestamo(OLD);
        return OLD;
    END;
    $function$
