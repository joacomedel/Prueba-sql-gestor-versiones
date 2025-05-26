CREATE OR REPLACE FUNCTION public.aeinformefacturacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacion(OLD);
        return OLD;
    END;
    $function$
