CREATE OR REPLACE FUNCTION public.amfar_liquidacionitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacionitems(NEW);
        return NEW;
    END;
    $function$
