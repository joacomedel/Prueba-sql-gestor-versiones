CREATE OR REPLACE FUNCTION public.aefichamedicaemisionpendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaemisionpendiente(OLD);
        return OLD;
    END;
    $function$
