CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemvaleregalo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemvaleregalo(NEW);
        return NEW;
    END;
    $function$
