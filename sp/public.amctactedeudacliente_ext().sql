CREATE OR REPLACE FUNCTION public.amctactedeudacliente_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctactedeudacliente_ext(NEW);
        return NEW;
    END;
    $function$
