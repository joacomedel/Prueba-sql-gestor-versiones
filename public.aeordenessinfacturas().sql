CREATE OR REPLACE FUNCTION public.aeordenessinfacturas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenessinfacturas(OLD);
        return OLD;
    END;
    $function$
