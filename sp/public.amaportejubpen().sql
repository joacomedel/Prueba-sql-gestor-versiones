CREATE OR REPLACE FUNCTION public.amaportejubpen()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaportejubpen(NEW);
        return NEW;
    END;
    $function$
