CREATE OR REPLACE FUNCTION public.aminformefacturacionnotadebito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionnotadebito(NEW);
        return NEW;
    END;
    $function$
