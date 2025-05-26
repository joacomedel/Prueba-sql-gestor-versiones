CREATE OR REPLACE FUNCTION public.aeprestadorctacte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestadorctacte(OLD);
        return OLD;
    END;
    $function$
