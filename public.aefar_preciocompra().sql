CREATE OR REPLACE FUNCTION public.aefar_preciocompra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_preciocompra(OLD);
        return OLD;
    END;
    $function$
