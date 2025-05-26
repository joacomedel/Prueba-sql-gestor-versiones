CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemvale()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemvale(OLD);
        return OLD;
    END;
    $function$
