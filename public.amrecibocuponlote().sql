CREATE OR REPLACE FUNCTION public.amrecibocuponlote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibocuponlote(NEW);
        return NEW;
    END;
    $function$
