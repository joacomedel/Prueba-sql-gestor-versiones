CREATE OR REPLACE FUNCTION public.aeinformefacturacionturismo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionturismo(OLD);
        return OLD;
    END;
    $function$
