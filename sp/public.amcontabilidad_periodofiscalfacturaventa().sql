CREATE OR REPLACE FUNCTION public.amcontabilidad_periodofiscalfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccontabilidad_periodofiscalfacturaventa(NEW);
        return NEW;
    END;
    $function$
