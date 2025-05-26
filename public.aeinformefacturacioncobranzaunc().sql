CREATE OR REPLACE FUNCTION public.aeinformefacturacioncobranzaunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacioncobranzaunc(OLD);
        return OLD;
    END;
    $function$
