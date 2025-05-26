CREATE OR REPLACE FUNCTION public.amfar_ordenventaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitem(NEW);
        return NEW;
    END;
    $function$
