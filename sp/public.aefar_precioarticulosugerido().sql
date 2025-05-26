CREATE OR REPLACE FUNCTION public.aefar_precioarticulosugerido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precioarticulosugerido(OLD);
        return OLD;
    END;
    $function$
