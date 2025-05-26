CREATE OR REPLACE FUNCTION public.aeconsumo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconsumo(OLD);
        return OLD;
    END;
    $function$
