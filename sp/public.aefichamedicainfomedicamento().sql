CREATE OR REPLACE FUNCTION public.aefichamedicainfomedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicainfomedicamento(OLD);
        return OLD;
    END;
    $function$
