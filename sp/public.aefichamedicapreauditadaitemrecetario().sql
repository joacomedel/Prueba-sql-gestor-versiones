CREATE OR REPLACE FUNCTION public.aefichamedicapreauditadaitemrecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicapreauditadaitemrecetario(OLD);
        return OLD;
    END;
    $function$
