CREATE OR REPLACE FUNCTION public.amfar_remitoestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_remitoestadotipo(NEW);
        return NEW;
    END;
    $function$
