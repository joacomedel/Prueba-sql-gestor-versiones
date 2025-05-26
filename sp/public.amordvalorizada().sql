CREATE OR REPLACE FUNCTION public.amordvalorizada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordvalorizada(NEW);
        return NEW;
    END;
    $function$
