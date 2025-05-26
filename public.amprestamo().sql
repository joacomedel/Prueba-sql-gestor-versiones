CREATE OR REPLACE FUNCTION public.amprestamo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestamo(NEW);
        return NEW;
    END;
    $function$
