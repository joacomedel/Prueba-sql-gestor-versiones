CREATE OR REPLACE FUNCTION public.aepagoordenpagocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpagoordenpagocontable(OLD);
        return OLD;
    END;
    $function$
