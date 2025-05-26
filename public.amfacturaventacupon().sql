CREATE OR REPLACE FUNCTION public.amfacturaventacupon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventacupon(NEW);
        return NEW;
    END;
    $function$
