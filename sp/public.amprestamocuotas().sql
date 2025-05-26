CREATE OR REPLACE FUNCTION public.amprestamocuotas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestamocuotas(NEW);
        return NEW;
    END;
    $function$
