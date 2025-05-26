CREATE OR REPLACE FUNCTION public.aminformefacturacioncobranzaunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinformefacturacioncobranzaunc(NEW);
        return NEW;
    END;
    $function$
