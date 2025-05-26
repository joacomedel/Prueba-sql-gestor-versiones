CREATE OR REPLACE FUNCTION public.amfar_remito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_remito(NEW);
        return NEW;
    END;
    $function$
