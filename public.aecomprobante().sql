CREATE OR REPLACE FUNCTION public.aecomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccomprobante(OLD);
        return OLD;
    END;
    $function$
