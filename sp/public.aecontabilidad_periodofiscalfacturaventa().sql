CREATE OR REPLACE FUNCTION public.aecontabilidad_periodofiscalfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccontabilidad_periodofiscalfacturaventa(OLD);
        return OLD;
    END;
    $function$
