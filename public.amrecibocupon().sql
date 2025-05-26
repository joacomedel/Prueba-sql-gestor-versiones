CREATE OR REPLACE FUNCTION public.amrecibocupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibocupon(NEW);
        return NEW;
    END;
    $function$
