CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemitemfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemitemfacturaventa(NEW);
        return NEW;
    END;
    $function$
