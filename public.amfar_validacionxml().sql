CREATE OR REPLACE FUNCTION public.amfar_validacionxml()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_validacionxml(NEW);
        return NEW;
    END;
    $function$
