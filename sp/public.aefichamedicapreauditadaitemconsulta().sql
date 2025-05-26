CREATE OR REPLACE FUNCTION public.aefichamedicapreauditadaitemconsulta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicapreauditadaitemconsulta(OLD);
        return OLD;
    END;
    $function$
