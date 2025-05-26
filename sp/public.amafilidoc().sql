CREATE OR REPLACE FUNCTION public.amafilidoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilidoc(NEW);
        return NEW;
    END;
    $function$
