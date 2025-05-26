CREATE OR REPLACE FUNCTION public.amordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpago(NEW);
        return NEW;
    END;
    $function$
