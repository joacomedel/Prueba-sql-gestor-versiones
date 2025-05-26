CREATE OR REPLACE FUNCTION public.amfar_obrasocialmutual()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_obrasocialmutual(NEW);
        return NEW;
    END;
    $function$
