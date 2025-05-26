CREATE OR REPLACE FUNCTION public.amfar_remitoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_remitoestado(NEW);
        return NEW;
    END;
    $function$
