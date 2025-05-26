CREATE OR REPLACE FUNCTION public.amprueba()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprueba(NEW);
        return NEW;
    END;
    $function$
