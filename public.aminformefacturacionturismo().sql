CREATE OR REPLACE FUNCTION public.aminformefacturacionturismo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionturismo(NEW);
        return NEW;
    END;
    $function$
