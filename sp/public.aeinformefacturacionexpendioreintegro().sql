CREATE OR REPLACE FUNCTION public.aeinformefacturacionexpendioreintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionexpendioreintegro(OLD);
        return OLD;
    END;
    $function$
