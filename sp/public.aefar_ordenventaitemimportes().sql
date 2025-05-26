CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemimportes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemimportes(OLD);
        return OLD;
    END;
    $function$
