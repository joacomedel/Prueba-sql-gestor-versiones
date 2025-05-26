CREATE OR REPLACE FUNCTION public.aminformefacturacionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionestado(NEW);
        return NEW;
    END;
    $function$
