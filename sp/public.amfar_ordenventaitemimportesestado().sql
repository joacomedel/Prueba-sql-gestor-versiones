CREATE OR REPLACE FUNCTION public.amfar_ordenventaitemimportesestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaitemimportesestado(NEW);
        return NEW;
    END;
    $function$
