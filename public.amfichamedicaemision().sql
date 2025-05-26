CREATE OR REPLACE FUNCTION public.amfichamedicaemision()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaemision(NEW);
        return NEW;
    END;
    $function$
