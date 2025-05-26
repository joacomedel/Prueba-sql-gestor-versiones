CREATE OR REPLACE FUNCTION public.amprorroga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprorroga(NEW);
        return NEW;
    END;
    $function$
