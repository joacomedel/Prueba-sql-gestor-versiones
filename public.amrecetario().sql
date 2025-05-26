CREATE OR REPLACE FUNCTION public.amrecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetario(NEW);
        return NEW;
    END;
    $function$
