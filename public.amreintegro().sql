CREATE OR REPLACE FUNCTION public.amreintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegro(NEW);
        return NEW;
    END;
    $function$
