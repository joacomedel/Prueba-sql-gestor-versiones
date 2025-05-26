CREATE OR REPLACE FUNCTION public.amfar_articulotrazabilidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articulotrazabilidad(NEW);
        return NEW;
    END;
    $function$
