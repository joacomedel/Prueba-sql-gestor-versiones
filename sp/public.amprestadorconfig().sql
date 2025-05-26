CREATE OR REPLACE FUNCTION public.amprestadorconfig()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestadorconfig(NEW);
        return NEW;
    END;
    $function$
