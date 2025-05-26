CREATE OR REPLACE FUNCTION public.amfar_validacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_validacion(NEW);
        return NEW;
    END;
    $function$
