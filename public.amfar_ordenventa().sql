CREATE OR REPLACE FUNCTION public.amfar_ordenventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventa(NEW);
        return NEW;
    END;
    $function$
