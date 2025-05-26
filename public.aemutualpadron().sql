CREATE OR REPLACE FUNCTION public.aemutualpadron()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmutualpadron(OLD);
        return OLD;
    END;
    $function$
