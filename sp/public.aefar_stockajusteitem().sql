CREATE OR REPLACE FUNCTION public.aefar_stockajusteitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajusteitem(OLD);
        return OLD;
    END;
    $function$
