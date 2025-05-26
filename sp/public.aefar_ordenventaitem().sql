CREATE OR REPLACE FUNCTION public.aefar_ordenventaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitem(OLD);
        return OLD;
    END;
    $function$
