CREATE OR REPLACE FUNCTION public.amfacturaventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventa(NEW);
        return NEW;
    END;
    $function$
