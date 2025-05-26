CREATE OR REPLACE FUNCTION public.amfar_obrasocialvalorescaja()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_obrasocialvalorescaja(NEW);
        return NEW;
    END;
    $function$
