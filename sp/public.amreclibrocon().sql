CREATE OR REPLACE FUNCTION public.amreclibrocon()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreclibrocon(NEW);
        return NEW;
    END;
    $function$
