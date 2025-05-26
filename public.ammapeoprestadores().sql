CREATE OR REPLACE FUNCTION public.ammapeoprestadores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmapeoprestadores(NEW);
        return NEW;
    END;
    $function$
