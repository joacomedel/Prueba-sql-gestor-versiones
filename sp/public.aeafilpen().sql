CREATE OR REPLACE FUNCTION public.aeafilpen()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilpen(OLD);
        return OLD;
    END;
    $function$
