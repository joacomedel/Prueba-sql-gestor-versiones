CREATE OR REPLACE FUNCTION public.amitemordenessinfactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccitemordenessinfactura(NEW);
        return NEW;
    END;
    $function$
