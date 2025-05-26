CREATE OR REPLACE FUNCTION public.aefar_deposito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_deposito(OLD);
        return OLD;
    END;
    $function$
