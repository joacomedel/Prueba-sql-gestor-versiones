CREATE OR REPLACE FUNCTION public.ammultidro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmultidro(NEW);
        return NEW;
    END;
    $function$
