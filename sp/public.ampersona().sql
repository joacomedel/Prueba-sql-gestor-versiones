CREATE OR REPLACE FUNCTION public.ampersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpersona(NEW);
        return NEW;
    END;
    $function$
