CREATE OR REPLACE FUNCTION public.amafilsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$    BEGIN
    NEW:= insertarccafilsosunc(NEW);
        return NEW;
    END;
    $function$
