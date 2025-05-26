CREATE OR REPLACE FUNCTION public.amrecetariotpitemuso()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetariotpitemuso(NEW);
        return NEW;
    END;
    $function$
