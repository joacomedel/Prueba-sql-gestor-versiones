CREATE OR REPLACE FUNCTION public.amaportessinfacturas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaportessinfacturas(NEW);
        return NEW;
    END;
    $function$
