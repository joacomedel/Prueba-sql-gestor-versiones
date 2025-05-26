CREATE OR REPLACE FUNCTION public.aeinformefacturacionnotadebito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionnotadebito(OLD);
        return OLD;
    END;
    $function$
