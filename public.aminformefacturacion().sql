CREATE OR REPLACE FUNCTION public.aminformefacturacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacion(NEW);
        return NEW;
    END;
    $function$
