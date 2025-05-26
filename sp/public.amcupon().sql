CREATE OR REPLACE FUNCTION public.amcupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccupon(NEW);
        return NEW;
    END;
    $function$
