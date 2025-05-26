CREATE OR REPLACE FUNCTION public.aeinformefacturacionitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionitem(OLD);
        return OLD;
    END;
    $function$
