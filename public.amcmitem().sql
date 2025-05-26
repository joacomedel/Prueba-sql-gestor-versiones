CREATE OR REPLACE FUNCTION public.amcmitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccmitem(NEW);
        return NEW;
    END;
    $function$
