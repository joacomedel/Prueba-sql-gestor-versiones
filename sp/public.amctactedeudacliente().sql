CREATE OR REPLACE FUNCTION public.amctactedeudacliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctactedeudacliente(NEW);
        return NEW;
    END;
    $function$
