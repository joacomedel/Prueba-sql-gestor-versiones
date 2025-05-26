CREATE OR REPLACE FUNCTION public.aerecetariotpitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetariotpitem(OLD);
        return OLD;
    END;
    $function$
