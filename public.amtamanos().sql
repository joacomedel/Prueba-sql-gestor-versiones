CREATE OR REPLACE FUNCTION public.amtamanos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctamanos(NEW);
        return NEW;
    END;
    $function$
