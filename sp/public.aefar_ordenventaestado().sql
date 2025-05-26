CREATE OR REPLACE FUNCTION public.aefar_ordenventaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaestado(OLD);
        return OLD;
    END;
    $function$
