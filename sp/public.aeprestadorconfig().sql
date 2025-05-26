CREATE OR REPLACE FUNCTION public.aeprestadorconfig()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestadorconfig(OLD);
        return OLD;
    END;
    $function$
