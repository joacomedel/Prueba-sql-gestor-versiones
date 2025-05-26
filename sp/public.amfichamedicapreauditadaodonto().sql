CREATE OR REPLACE FUNCTION public.amfichamedicapreauditadaodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicapreauditadaodonto(NEW);
        return NEW;
    END;
    $function$
