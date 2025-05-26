CREATE OR REPLACE FUNCTION public.aeordenpagocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpagocontable(OLD);
        return OLD;
    END;
    $function$
