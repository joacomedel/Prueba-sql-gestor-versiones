CREATE OR REPLACE FUNCTION public.amfichamedicapreauditadaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicapreauditadaitem(NEW);
        return NEW;
    END;
    $function$
