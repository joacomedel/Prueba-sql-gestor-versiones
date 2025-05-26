CREATE OR REPLACE FUNCTION public.amimportesorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccimportesorden(NEW);
        return NEW;
    END;
    $function$
