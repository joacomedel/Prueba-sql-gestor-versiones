CREATE OR REPLACE FUNCTION public.amfichamedicatratamiento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicatratamiento(NEW);
        return NEW;
    END;
    $function$
