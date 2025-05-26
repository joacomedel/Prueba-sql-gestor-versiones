CREATE OR REPLACE FUNCTION public.aecupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccupon(OLD);
        return OLD;
    END;
    $function$
