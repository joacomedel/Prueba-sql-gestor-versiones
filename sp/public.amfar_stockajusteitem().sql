CREATE OR REPLACE FUNCTION public.amfar_stockajusteitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajusteitem(NEW);
        return NEW;
    END;
    $function$
