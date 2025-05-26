CREATE OR REPLACE FUNCTION public.aemapea_certdisc_alcancecobertura_fichamedicaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmapea_certdisc_alcancecobertura_fichamedicaitem(OLD);
        return OLD;
    END;
    $function$
