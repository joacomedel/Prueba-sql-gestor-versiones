CREATE OR REPLACE FUNCTION public.amfar_liquidacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacion(NEW);
        return NEW;
    END;
    $function$
