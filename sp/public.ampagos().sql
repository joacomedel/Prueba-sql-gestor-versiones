CREATE OR REPLACE FUNCTION public.ampagos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpagos(NEW);
        return NEW;
    END;
    $function$
