CREATE OR REPLACE FUNCTION public.amfar_obrasocial()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_obrasocial(NEW);
        return NEW;
    END;
    $function$
