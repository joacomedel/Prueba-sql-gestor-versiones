CREATE OR REPLACE FUNCTION public.aefacturaventa_quitardeliq()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventa_quitardeliq(OLD);
        return OLD;
    END;
    $function$
