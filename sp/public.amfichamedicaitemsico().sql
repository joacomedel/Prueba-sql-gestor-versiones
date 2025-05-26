CREATE OR REPLACE FUNCTION public.amfichamedicaitemsico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaitemsico(NEW);
        return NEW;
    END;
    $function$
