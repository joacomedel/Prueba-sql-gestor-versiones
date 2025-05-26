CREATE OR REPLACE FUNCTION public.aefar_remito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_remito(OLD);
        return OLD;
    END;
    $function$
