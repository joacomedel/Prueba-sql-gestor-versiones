CREATE OR REPLACE FUNCTION public.amfar_rubro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_rubro(NEW);
        return NEW;
    END;
    $function$
