CREATE OR REPLACE FUNCTION public.amfar_ordenventareceta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventareceta(NEW);
        return NEW;
    END;
    $function$
