CREATE OR REPLACE FUNCTION public.amfar_parametros()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_parametros(NEW);
        return NEW;
    END;
    $function$
