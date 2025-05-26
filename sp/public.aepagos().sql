CREATE OR REPLACE FUNCTION public.aepagos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpagos(OLD);
        return OLD;
    END;
    $function$
