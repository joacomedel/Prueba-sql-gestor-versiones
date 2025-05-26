CREATE OR REPLACE FUNCTION public.aeactasdefun()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccactasdefun(OLD);
        return OLD;
    END;
    $function$
