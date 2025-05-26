CREATE OR REPLACE FUNCTION public.amfar_ordenventaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaestado(NEW);
        return NEW;
    END;
    $function$
