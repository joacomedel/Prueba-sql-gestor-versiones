CREATE OR REPLACE FUNCTION public.ammapea_certdisc_alcancecobertura_fichamedicaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmapea_certdisc_alcancecobertura_fichamedicaitem(NEW);
        return NEW;
    END;
    $function$
