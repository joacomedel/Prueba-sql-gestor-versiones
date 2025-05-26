CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemestado(NEW);
        return NEW;
    END;
    $function$
