CREATE OR REPLACE FUNCTION public.aeafiljub()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafiljub(OLD);
        return OLD;
    END;
    $function$
