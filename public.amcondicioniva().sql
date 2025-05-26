CREATE OR REPLACE FUNCTION public.amcondicioniva()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccondicioniva(NEW);
        return NEW;
    END;
    $function$
