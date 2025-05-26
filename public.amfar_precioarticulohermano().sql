CREATE OR REPLACE FUNCTION public.amfar_precioarticulohermano()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precioarticulohermano(NEW);
        return NEW;
    END;
    $function$
