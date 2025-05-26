CREATE OR REPLACE FUNCTION public.aepase()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpase(OLD);
        return OLD;
    END;
    $function$
