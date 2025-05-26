CREATE OR REPLACE FUNCTION public.amcertpersonal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccertpersonal(NEW);
        return NEW;
    END;
    $function$
