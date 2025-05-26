CREATE OR REPLACE FUNCTION public.amfacturaordenesutilizadas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaordenesutilizadas(NEW);
        return NEW;
    END;
    $function$
