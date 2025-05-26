CREATE OR REPLACE FUNCTION public.amorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccorden(NEW);
        return NEW;
    END;
    $function$
