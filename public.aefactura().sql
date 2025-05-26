CREATE OR REPLACE FUNCTION public.aefactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfactura(OLD);
        return OLD;
    END;
    $function$
