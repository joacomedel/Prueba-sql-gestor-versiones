CREATE OR REPLACE FUNCTION public.aeconsumoturismovalores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconsumoturismovalores(OLD);
        return OLD;
    END;
    $function$
