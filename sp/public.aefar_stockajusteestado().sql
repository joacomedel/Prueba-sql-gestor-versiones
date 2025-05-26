CREATE OR REPLACE FUNCTION public.aefar_stockajusteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajusteestado(OLD);
        return OLD;
    END;
    $function$
