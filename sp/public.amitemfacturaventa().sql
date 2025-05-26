CREATE OR REPLACE FUNCTION public.amitemfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccitemfacturaventa(NEW);
        return NEW;
    END;
    $function$
