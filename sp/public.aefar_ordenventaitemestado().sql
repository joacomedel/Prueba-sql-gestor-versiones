CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemestado(OLD);
        return OLD;
    END;
    $function$
