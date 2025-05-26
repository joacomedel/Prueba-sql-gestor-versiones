CREATE OR REPLACE FUNCTION public.amfar_stockajusteestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajusteestadotipo(NEW);
        return NEW;
    END;
    $function$
