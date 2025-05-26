CREATE OR REPLACE FUNCTION public.aeafilreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilreci(OLD);
        return OLD;
    END;
    $function$
