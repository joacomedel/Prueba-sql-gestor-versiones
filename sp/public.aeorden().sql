CREATE OR REPLACE FUNCTION public.aeorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccorden(OLD);
        return OLD;
    END;
    $function$
