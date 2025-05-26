CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemitemfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemitemfacturaventa(OLD);
        return OLD;
    END;
    $function$
