CREATE OR REPLACE FUNCTION public.amafiliauto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafiliauto(NEW);
        return NEW;
    END;
    $function$
