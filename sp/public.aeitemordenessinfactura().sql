CREATE OR REPLACE FUNCTION public.aeitemordenessinfactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccitemordenessinfactura(OLD);
        return OLD;
    END;
    $function$
