CREATE OR REPLACE FUNCTION public.aminformefacturacionexpendioreintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacionexpendioreintegro(NEW);
        return NEW;
    END;
    $function$
