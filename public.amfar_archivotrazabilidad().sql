CREATE OR REPLACE FUNCTION public.amfar_archivotrazabilidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_archivotrazabilidad(NEW);
        return NEW;
    END;
    $function$
