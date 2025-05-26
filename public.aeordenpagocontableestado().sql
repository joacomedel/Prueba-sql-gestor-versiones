CREATE OR REPLACE FUNCTION public.aeordenpagocontableestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpagocontableestado(OLD);
        return OLD;
    END;
    $function$
