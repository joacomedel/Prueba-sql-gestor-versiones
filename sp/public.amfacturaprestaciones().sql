CREATE OR REPLACE FUNCTION public.amfacturaprestaciones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaprestaciones(NEW);
        return NEW;
    END;
    $function$
