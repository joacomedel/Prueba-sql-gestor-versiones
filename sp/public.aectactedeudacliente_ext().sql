CREATE OR REPLACE FUNCTION public.aectactedeudacliente_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctactedeudacliente_ext(OLD);
        return OLD;
    END;
    $function$
