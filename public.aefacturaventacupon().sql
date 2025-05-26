CREATE OR REPLACE FUNCTION public.aefacturaventacupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventacupon(OLD);
        return OLD;
    END;
    $function$
