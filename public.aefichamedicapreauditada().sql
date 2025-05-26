CREATE OR REPLACE FUNCTION public.aefichamedicapreauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicapreauditada(OLD);
        return OLD;
    END;
    $function$
