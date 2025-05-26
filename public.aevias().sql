CREATE OR REPLACE FUNCTION public.aevias()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccvias(OLD);
        return OLD;
    END;
    $function$
