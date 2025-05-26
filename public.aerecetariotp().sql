CREATE OR REPLACE FUNCTION public.aerecetariotp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetariotp(OLD);
        return OLD;
    END;
    $function$
