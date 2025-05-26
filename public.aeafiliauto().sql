CREATE OR REPLACE FUNCTION public.aeafiliauto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafiliauto(OLD);
        return OLD;
    END;
    $function$
