CREATE OR REPLACE FUNCTION public.aefar_precioarticulohermano()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precioarticulohermano(OLD);
        return OLD;
    END;
    $function$
