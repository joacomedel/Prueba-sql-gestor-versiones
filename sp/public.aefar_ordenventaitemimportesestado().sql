CREATE OR REPLACE FUNCTION public.aefar_ordenventaitemimportesestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaitemimportesestado(OLD);
        return OLD;
    END;
    $function$
