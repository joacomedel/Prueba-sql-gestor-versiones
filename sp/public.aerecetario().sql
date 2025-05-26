CREATE OR REPLACE FUNCTION public.aerecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetario(OLD);
        return OLD;
    END;
    $function$
