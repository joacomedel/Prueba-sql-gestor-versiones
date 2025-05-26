CREATE OR REPLACE FUNCTION public.amcatalogoordencomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccatalogoordencomprobante(NEW);
        return NEW;
    END;
    $function$
