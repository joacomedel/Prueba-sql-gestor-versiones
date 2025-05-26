CREATE OR REPLACE FUNCTION public.aeordenesreemitidas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenesreemitidas(OLD);
        return OLD;
    END;
    $function$
