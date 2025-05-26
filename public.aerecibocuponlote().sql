CREATE OR REPLACE FUNCTION public.aerecibocuponlote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibocuponlote(OLD);
        return OLD;
    END;
    $function$
