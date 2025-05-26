CREATE OR REPLACE FUNCTION public.aectactedeudapagoclienteordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctactedeudapagoclienteordenpago(OLD);
        return OLD;
    END;
    $function$
