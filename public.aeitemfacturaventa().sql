CREATE OR REPLACE FUNCTION public.aeitemfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccitemfacturaventa(OLD);
        return OLD;
    END;
    $function$
