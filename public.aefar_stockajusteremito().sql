CREATE OR REPLACE FUNCTION public.aefar_stockajusteremito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajusteremito(OLD);
        return OLD;
    END;
    $function$
