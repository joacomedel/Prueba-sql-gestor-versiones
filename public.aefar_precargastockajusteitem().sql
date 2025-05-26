CREATE OR REPLACE FUNCTION public.aefar_precargastockajusteitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargastockajusteitem(OLD);
        return OLD;
    END;
    $function$
