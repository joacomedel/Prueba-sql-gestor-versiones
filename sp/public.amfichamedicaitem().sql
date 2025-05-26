CREATE OR REPLACE FUNCTION public.amfichamedicaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaitem(NEW);
        return NEW;
    END;
    $function$
