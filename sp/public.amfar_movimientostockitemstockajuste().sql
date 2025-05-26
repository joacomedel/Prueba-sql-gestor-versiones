CREATE OR REPLACE FUNCTION public.amfar_movimientostockitemstockajuste()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostockitemstockajuste(NEW);
        return NEW;
    END;
    $function$
