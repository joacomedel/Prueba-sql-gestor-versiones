CREATE OR REPLACE FUNCTION public.aefichamedicaemisionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaemisionestado(OLD);
        return OLD;
    END;
    $function$
