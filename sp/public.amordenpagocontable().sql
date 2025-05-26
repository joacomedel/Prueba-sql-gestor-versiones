CREATE OR REPLACE FUNCTION public.amordenpagocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpagocontable(NEW);
        return NEW;
    END;
    $function$
