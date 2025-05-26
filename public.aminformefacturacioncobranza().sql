CREATE OR REPLACE FUNCTION public.aminformefacturacioncobranza()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacioncobranza(NEW);
        return NEW;
    END;
    $function$
