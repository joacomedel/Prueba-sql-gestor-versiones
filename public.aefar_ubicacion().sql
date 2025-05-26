CREATE OR REPLACE FUNCTION public.aefar_ubicacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ubicacion(OLD);
        return OLD;
    END;
    $function$
