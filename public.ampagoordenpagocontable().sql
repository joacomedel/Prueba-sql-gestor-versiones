CREATE OR REPLACE FUNCTION public.ampagoordenpagocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpagoordenpagocontable(NEW);
        return NEW;
    END;
    $function$
