CREATE OR REPLACE FUNCTION public.aerecreintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecreintegro(OLD);
        return OLD;
    END;
    $function$
