CREATE OR REPLACE FUNCTION public.aeinformefacturacionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinformefacturacionestado(OLD);
        return OLD;
    END;
    $function$
