CREATE OR REPLACE FUNCTION public.amfichamedicaemisionpendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaemisionpendiente(NEW);
        return NEW;
    END;
    $function$
