CREATE OR REPLACE FUNCTION public.aeinformefacturacioncobranza()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacioncobranza(OLD);
        return OLD;
    END;
    $function$
