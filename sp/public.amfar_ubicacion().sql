CREATE OR REPLACE FUNCTION public.amfar_ubicacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ubicacion(NEW);
        return NEW;
    END;
    $function$
