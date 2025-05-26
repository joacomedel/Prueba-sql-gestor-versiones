CREATE OR REPLACE FUNCTION public.aeordenpagocontablereintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpagocontablereintegro(OLD);
        return OLD;
    END;
    $function$
