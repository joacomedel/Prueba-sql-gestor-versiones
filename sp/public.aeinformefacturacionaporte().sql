CREATE OR REPLACE FUNCTION public.aeinformefacturacionaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionaporte(OLD);
        return OLD;
    END;
    $function$
