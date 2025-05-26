CREATE OR REPLACE FUNCTION public.aefichamedicapreauditadaodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicapreauditadaodonto(OLD);
        return OLD;
    END;
    $function$
