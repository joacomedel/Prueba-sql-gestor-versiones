CREATE OR REPLACE FUNCTION public.amformas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccformas(NEW);
        return NEW;
    END;
    $function$
