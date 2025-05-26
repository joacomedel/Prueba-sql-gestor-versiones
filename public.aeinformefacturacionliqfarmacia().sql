CREATE OR REPLACE FUNCTION public.aeinformefacturacionliqfarmacia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionliqfarmacia(OLD);
        return OLD;
    END;
    $function$
