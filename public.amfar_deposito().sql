CREATE OR REPLACE FUNCTION public.amfar_deposito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_deposito(NEW);
        return NEW;
    END;
    $function$
