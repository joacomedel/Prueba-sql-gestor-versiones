CREATE OR REPLACE FUNCTION public.amfacturaventa_quitardeliq()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventa_quitardeliq(NEW);
        return NEW;
    END;
    $function$
