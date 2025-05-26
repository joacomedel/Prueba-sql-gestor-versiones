CREATE OR REPLACE FUNCTION public.aeprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestador(OLD);
        return OLD;
    END;
    $function$
