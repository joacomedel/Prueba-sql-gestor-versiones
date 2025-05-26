CREATE OR REPLACE FUNCTION public.aefar_ordenventareceta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventareceta(OLD);
        return OLD;
    END;
    $function$
