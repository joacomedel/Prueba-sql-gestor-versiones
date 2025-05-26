CREATE OR REPLACE FUNCTION public.amfichamedicaitempendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaitempendiente(NEW);
        return NEW;
    END;
    $function$
