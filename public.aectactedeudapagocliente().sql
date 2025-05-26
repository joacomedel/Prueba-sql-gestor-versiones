CREATE OR REPLACE FUNCTION public.aectactedeudapagocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctactedeudapagocliente(OLD);
        return OLD;
    END;
    $function$
