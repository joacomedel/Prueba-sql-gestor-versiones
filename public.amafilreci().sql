CREATE OR REPLACE FUNCTION public.amafilreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilreci(NEW);
        return NEW;
    END;
    $function$
