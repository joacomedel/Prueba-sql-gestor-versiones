CREATE OR REPLACE FUNCTION public.aereclibrocon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreclibrocon(OLD);
        return OLD;
    END;
    $function$
