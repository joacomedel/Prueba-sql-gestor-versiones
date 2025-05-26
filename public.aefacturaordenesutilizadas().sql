CREATE OR REPLACE FUNCTION public.aefacturaordenesutilizadas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaordenesutilizadas(OLD);
        return OLD;
    END;
    $function$
