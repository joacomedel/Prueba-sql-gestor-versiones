CREATE OR REPLACE FUNCTION public.aminformefacturacionliqfarmacia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionliqfarmacia(NEW);
        return NEW;
    END;
    $function$
