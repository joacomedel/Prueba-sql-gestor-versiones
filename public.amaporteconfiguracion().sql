CREATE OR REPLACE FUNCTION public.amaporteconfiguracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaporteconfiguracion(NEW);
        return NEW;
    END;
    $function$
