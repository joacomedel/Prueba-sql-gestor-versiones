CREATE OR REPLACE FUNCTION public.aefacturaorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaorden(OLD);
        return OLD;
    END;
    $function$
