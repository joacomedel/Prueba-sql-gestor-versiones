CREATE OR REPLACE FUNCTION public.amfar_stockajusteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajusteestado(NEW);
        return NEW;
    END;
    $function$
