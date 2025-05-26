CREATE OR REPLACE FUNCTION public.aefar_stockajuste()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajuste(OLD);
        return OLD;
    END;
    $function$
