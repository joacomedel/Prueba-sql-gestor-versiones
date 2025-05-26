CREATE OR REPLACE FUNCTION public.aefar_precioarticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precioarticulo(OLD);
        return OLD;
    END;
    $function$
