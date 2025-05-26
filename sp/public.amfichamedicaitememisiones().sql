CREATE OR REPLACE FUNCTION public.amfichamedicaitememisiones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaitememisiones(NEW);
        return NEW;
    END;
    $function$
