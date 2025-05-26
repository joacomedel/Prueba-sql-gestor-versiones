CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemimportes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemimportes(NEW);
        return NEW;
    END;
    $function$
