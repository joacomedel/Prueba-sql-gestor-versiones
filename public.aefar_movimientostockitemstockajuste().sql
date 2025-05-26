CREATE OR REPLACE FUNCTION public.aefar_movimientostockitemstockajuste()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostockitemstockajuste(OLD);
        return OLD;
    END;
    $function$
