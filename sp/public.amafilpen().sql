CREATE OR REPLACE FUNCTION public.amafilpen()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilpen(NEW);
        return NEW;
    END;
    $function$
