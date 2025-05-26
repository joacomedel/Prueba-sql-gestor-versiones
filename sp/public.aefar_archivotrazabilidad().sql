CREATE OR REPLACE FUNCTION public.aefar_archivotrazabilidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_archivotrazabilidad(OLD);
        return OLD;
    END;
    $function$
