CREATE OR REPLACE FUNCTION public.aefacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventa(OLD);
        return OLD;
    END;
    $function$
