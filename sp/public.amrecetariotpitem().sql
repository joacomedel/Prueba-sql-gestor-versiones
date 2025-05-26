CREATE OR REPLACE FUNCTION public.amrecetariotpitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetariotpitem(NEW);
        return NEW;
    END;
    $function$
