CREATE OR REPLACE FUNCTION public.ammatricula()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmatricula(NEW);
        return NEW;
    END;
    $function$
