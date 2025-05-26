CREATE OR REPLACE FUNCTION public.amfar_configura_reporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_configura_reporte(NEW);
        return NEW;
    END;
    $function$
