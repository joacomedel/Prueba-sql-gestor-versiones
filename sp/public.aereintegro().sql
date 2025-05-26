CREATE OR REPLACE FUNCTION public.aereintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegro(OLD);
        return OLD;
    END;
    $function$
