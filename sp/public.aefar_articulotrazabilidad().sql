CREATE OR REPLACE FUNCTION public.aefar_articulotrazabilidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articulotrazabilidad(OLD);
        return OLD;
    END;
    $function$
