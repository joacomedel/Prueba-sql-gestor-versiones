CREATE OR REPLACE FUNCTION public.amfar_parametrosvalores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_parametrosvalores(NEW);
        return NEW;
    END;
    $function$
