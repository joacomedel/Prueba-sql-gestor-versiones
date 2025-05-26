CREATE OR REPLACE FUNCTION public.aeafilsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilsosunc(OLD);
        return OLD;
    END;
    $function$
