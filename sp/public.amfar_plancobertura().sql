CREATE OR REPLACE FUNCTION public.amfar_plancobertura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_plancobertura(NEW);
        return NEW;
    END;
    $function$
