CREATE OR REPLACE FUNCTION public.amrecreintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecreintegro(NEW);
        return NEW;
    END;
    $function$
