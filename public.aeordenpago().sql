CREATE OR REPLACE FUNCTION public.aeordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpago(OLD);
        return OLD;
    END;
    $function$
