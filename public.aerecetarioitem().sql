CREATE OR REPLACE FUNCTION public.aerecetarioitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetarioitem(OLD);
        return OLD;
    END;
    $function$
