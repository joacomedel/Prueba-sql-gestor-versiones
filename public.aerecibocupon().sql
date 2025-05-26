CREATE OR REPLACE FUNCTION public.aerecibocupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibocupon(OLD);
        return OLD;
    END;
    $function$
