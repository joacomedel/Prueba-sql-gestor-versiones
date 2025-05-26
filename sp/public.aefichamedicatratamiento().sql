CREATE OR REPLACE FUNCTION public.aefichamedicatratamiento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicatratamiento(OLD);
        return OLD;
    END;
    $function$
