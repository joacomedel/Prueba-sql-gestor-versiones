CREATE OR REPLACE FUNCTION public.amfar_precargastockajusteitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargastockajusteitem(NEW);
        return NEW;
    END;
    $function$
