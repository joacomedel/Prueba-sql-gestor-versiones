CREATE OR REPLACE FUNCTION public.aeaportessinfacturas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaportessinfacturas(OLD);
        return OLD;
    END;
    $function$
