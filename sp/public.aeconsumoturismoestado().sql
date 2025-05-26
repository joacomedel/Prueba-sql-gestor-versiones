CREATE OR REPLACE FUNCTION public.aeconsumoturismoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconsumoturismoestado(OLD);
        return OLD;
    END;
    $function$
