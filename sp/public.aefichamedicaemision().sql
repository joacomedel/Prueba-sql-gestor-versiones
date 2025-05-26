CREATE OR REPLACE FUNCTION public.aefichamedicaemision()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaemision(OLD);
        return OLD;
    END;
    $function$
