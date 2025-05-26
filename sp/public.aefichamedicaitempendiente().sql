CREATE OR REPLACE FUNCTION public.aefichamedicaitempendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaitempendiente(OLD);
        return OLD;
    END;
    $function$
