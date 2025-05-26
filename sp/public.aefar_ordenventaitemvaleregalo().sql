CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemvaleregalo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemvaleregalo(OLD);
        return OLD;
    END;
    $function$
