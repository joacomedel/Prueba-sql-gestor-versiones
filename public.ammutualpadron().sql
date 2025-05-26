CREATE OR REPLACE FUNCTION public.ammutualpadron()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmutualpadron(NEW);
        return NEW;
    END;
    $function$
