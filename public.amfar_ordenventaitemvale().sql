CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemvale()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemvale(NEW);
        return NEW;
    END;
    $function$
