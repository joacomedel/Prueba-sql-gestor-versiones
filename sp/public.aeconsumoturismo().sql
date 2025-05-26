CREATE OR REPLACE FUNCTION public.aeconsumoturismo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconsumoturismo(OLD);
        return OLD;
    END;
    $function$
