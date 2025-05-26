CREATE OR REPLACE FUNCTION public.aefar_configura_reporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_configura_reporte(OLD);
        return OLD;
    END;
    $function$
