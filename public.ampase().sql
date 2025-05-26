CREATE OR REPLACE FUNCTION public.ampase()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpase(NEW);
        return NEW;
    END;
    $function$
