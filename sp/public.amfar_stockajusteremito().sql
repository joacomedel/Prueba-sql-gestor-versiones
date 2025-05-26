CREATE OR REPLACE FUNCTION public.amfar_stockajusteremito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajusteremito(NEW);
        return NEW;
    END;
    $function$
