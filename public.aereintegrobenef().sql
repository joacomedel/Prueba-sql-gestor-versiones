CREATE OR REPLACE FUNCTION public.aereintegrobenef()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegrobenef(OLD);
        return OLD;
    END;
    $function$
