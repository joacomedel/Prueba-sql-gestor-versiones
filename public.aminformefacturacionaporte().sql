CREATE OR REPLACE FUNCTION public.aminformefacturacionaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionaporte(NEW);
        return NEW;
    END;
    $function$
