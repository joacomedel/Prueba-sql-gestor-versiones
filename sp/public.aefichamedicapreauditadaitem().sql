CREATE OR REPLACE FUNCTION public.aefichamedicapreauditadaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicapreauditadaitem(OLD);
        return OLD;
    END;
    $function$
