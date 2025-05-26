CREATE OR REPLACE FUNCTION public.aeprorroga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprorroga(OLD);
        return OLD;
    END;
    $function$
