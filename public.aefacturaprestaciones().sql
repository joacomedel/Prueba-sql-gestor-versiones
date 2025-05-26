CREATE OR REPLACE FUNCTION public.aefacturaprestaciones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaprestaciones(OLD);
        return OLD;
    END;
    $function$
