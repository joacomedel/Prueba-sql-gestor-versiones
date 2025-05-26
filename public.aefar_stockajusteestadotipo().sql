CREATE OR REPLACE FUNCTION public.aefar_stockajusteestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajusteestadotipo(OLD);
        return OLD;
    END;
    $function$
