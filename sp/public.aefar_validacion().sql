CREATE OR REPLACE FUNCTION public.aefar_validacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_validacion(OLD);
        return OLD;
    END;
    $function$
