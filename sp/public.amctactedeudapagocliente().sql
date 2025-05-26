CREATE OR REPLACE FUNCTION public.amctactedeudapagocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctactedeudapagocliente(NEW);
        return NEW;
    END;
    $function$
