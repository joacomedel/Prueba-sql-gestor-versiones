CREATE OR REPLACE FUNCTION public.amfar_oviiformapago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_oviiformapago(NEW);
        return NEW;
    END;
    $function$
