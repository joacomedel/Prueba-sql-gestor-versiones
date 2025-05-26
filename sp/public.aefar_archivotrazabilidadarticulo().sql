CREATE OR REPLACE FUNCTION public.aefar_archivotrazabilidadarticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_archivotrazabilidadarticulo(OLD);
        return OLD;
    END;
    $function$
