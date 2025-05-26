CREATE OR REPLACE FUNCTION public.amrecetarioconvenio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetarioconvenio(NEW);
        return NEW;
    END;
    $function$
