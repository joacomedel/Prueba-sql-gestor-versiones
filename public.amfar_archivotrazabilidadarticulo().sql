CREATE OR REPLACE FUNCTION public.amfar_archivotrazabilidadarticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_archivotrazabilidadarticulo(NEW);
        return NEW;
    END;
    $function$
