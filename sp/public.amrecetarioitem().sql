CREATE OR REPLACE FUNCTION public.amrecetarioitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetarioitem(NEW);
        return NEW;
    END;
    $function$
