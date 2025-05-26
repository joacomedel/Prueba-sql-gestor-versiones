CREATE OR REPLACE FUNCTION public.amanticipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccanticipo(NEW);
        return NEW;
    END;
    $function$
