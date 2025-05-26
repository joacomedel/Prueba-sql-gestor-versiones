CREATE OR REPLACE FUNCTION public.aefar_ordenventaestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaestadotipo(OLD);
        return OLD;
    END;
    $function$
