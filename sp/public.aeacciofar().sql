CREATE OR REPLACE FUNCTION public.aeacciofar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccacciofar(OLD);
        return OLD;
    END;
    $function$
