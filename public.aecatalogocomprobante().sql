CREATE OR REPLACE FUNCTION public.aecatalogocomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccatalogocomprobante(OLD);
        return OLD;
    END;
    $function$
