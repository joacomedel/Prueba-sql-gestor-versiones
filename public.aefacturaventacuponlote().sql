CREATE OR REPLACE FUNCTION public.aefacturaventacuponlote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventacuponlote(OLD);
        return OLD;
    END;
    $function$
