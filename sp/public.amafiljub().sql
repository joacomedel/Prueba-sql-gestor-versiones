CREATE OR REPLACE FUNCTION public.amafiljub()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafiljub(NEW);
        return NEW;
    END;
    $function$
