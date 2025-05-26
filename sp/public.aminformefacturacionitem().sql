CREATE OR REPLACE FUNCTION public.aminformefacturacionitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionitem(NEW);
        return NEW;
    END;
    $function$
