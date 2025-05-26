CREATE OR REPLACE FUNCTION public.aeitemvalorizada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccitemvalorizada(OLD);
        return OLD;
    END;
    $function$
