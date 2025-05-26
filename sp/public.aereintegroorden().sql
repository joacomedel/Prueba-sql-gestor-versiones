CREATE OR REPLACE FUNCTION public.aereintegroorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegroorden(OLD);
        return OLD;
    END;
    $function$
