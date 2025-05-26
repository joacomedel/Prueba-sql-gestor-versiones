CREATE OR REPLACE FUNCTION public.amclientectacte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccclientectacte(NEW);
        return NEW;
    END;
    $function$
