CREATE OR REPLACE FUNCTION public.ammotivodebito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmotivodebito(NEW);
        return NEW;
    END;
    $function$
