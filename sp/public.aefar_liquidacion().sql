CREATE OR REPLACE FUNCTION public.aefar_liquidacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacion(OLD);
        return OLD;
    END;
    $function$
