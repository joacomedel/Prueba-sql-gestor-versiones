CREATE OR REPLACE FUNCTION public.amfar_stockajuste()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajuste(NEW);
        return NEW;
    END;
    $function$
