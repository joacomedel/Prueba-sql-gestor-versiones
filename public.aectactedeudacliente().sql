CREATE OR REPLACE FUNCTION public.aectactedeudacliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctactedeudacliente(OLD);
        return OLD;
    END;
    $function$
