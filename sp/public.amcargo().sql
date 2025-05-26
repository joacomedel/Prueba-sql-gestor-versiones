CREATE OR REPLACE FUNCTION public.amcargo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccargo(NEW);
        return NEW;
    END;
    $function$
