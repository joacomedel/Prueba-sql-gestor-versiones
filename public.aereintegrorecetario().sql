CREATE OR REPLACE FUNCTION public.aereintegrorecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegrorecetario(OLD);
        return OLD;
    END;
    $function$
