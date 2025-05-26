CREATE OR REPLACE FUNCTION public.aerecetariotpitemuso()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetariotpitemuso(OLD);
        return OLD;
    END;
    $function$
