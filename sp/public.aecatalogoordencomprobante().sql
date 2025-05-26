CREATE OR REPLACE FUNCTION public.aecatalogoordencomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccatalogoordencomprobante(OLD);
        return OLD;
    END;
    $function$
