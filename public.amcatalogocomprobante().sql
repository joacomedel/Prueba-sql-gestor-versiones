CREATE OR REPLACE FUNCTION public.amcatalogocomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccatalogocomprobante(NEW);
        return NEW;
    END;
    $function$
