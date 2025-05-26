CREATE OR REPLACE FUNCTION public.amfar_ordenventaestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaestadotipo(NEW);
        return NEW;
    END;
    $function$
