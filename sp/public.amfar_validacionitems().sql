CREATE OR REPLACE FUNCTION public.amfar_validacionitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_validacionitems(NEW);
        return NEW;
    END;
    $function$
