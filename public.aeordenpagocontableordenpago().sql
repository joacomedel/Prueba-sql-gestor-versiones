CREATE OR REPLACE FUNCTION public.aeordenpagocontableordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpagocontableordenpago(OLD);
        return OLD;
    END;
    $function$
