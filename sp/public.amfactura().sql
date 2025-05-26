CREATE OR REPLACE FUNCTION public.amfactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfactura(NEW);
        return NEW;
    END;
    $function$
