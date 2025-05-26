CREATE OR REPLACE FUNCTION public.amrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibo(NEW);
        return NEW;
    END;
    $function$
