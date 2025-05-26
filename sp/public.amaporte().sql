CREATE OR REPLACE FUNCTION public.amaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaporte(NEW);
        return NEW;
    END;
    $function$
