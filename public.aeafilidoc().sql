CREATE OR REPLACE FUNCTION public.aeafilidoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilidoc(OLD);
        return OLD;
    END;
    $function$
