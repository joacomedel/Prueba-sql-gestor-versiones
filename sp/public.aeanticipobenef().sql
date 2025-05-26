CREATE OR REPLACE FUNCTION public.aeanticipobenef()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccanticipobenef(OLD);
        return OLD;
    END;
    $function$
