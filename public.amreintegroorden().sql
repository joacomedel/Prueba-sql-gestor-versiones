CREATE OR REPLACE FUNCTION public.amreintegroorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegroorden(NEW);
        return NEW;
    END;
    $function$
