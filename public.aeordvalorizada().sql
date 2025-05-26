CREATE OR REPLACE FUNCTION public.aeordvalorizada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordvalorizada(OLD);
        return OLD;
    END;
    $function$
