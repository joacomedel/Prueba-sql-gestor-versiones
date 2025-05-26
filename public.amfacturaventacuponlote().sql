CREATE OR REPLACE FUNCTION public.amfacturaventacuponlote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventacuponlote(NEW);
        return NEW;
    END;
    $function$
