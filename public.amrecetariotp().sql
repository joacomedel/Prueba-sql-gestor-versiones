CREATE OR REPLACE FUNCTION public.amrecetariotp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetariotp(NEW);
        return NEW;
    END;
    $function$
