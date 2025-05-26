CREATE OR REPLACE FUNCTION public.aeordinternacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordinternacion(OLD);
        return OLD;
    END;
    $function$
