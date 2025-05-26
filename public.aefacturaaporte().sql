CREATE OR REPLACE FUNCTION public.aefacturaaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaaporte(OLD);
        return OLD;
    END;
    $function$
