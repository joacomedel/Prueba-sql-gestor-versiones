CREATE OR REPLACE FUNCTION public.aeprueba()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprueba(OLD);
        return OLD;
    END;
    $function$
