CREATE OR REPLACE FUNCTION public.aeordenesutilizadas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenesutilizadas(OLD);
        return OLD;
    END;
    $function$
