CREATE OR REPLACE FUNCTION public.aeimportesorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccimportesorden(OLD);
        return OLD;
    END;
    $function$
