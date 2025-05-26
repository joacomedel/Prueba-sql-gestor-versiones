CREATE OR REPLACE FUNCTION public.amfar_remitoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_remitoitem(NEW);
        return NEW;
    END;
    $function$
