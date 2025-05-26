CREATE OR REPLACE FUNCTION public.amitemvalorizada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccitemvalorizada(NEW);
        return NEW;
    END;
    $function$
