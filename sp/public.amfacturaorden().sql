CREATE OR REPLACE FUNCTION public.amfacturaorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaorden(NEW);
        return NEW;
    END;
    $function$
