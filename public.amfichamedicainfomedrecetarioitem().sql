CREATE OR REPLACE FUNCTION public.amfichamedicainfomedrecetarioitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicainfomedrecetarioitem(NEW);
        return NEW;
    END;
    $function$
