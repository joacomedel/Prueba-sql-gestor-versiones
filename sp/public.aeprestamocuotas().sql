CREATE OR REPLACE FUNCTION public.aeprestamocuotas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestamocuotas(OLD);
        return OLD;
    END;
    $function$
