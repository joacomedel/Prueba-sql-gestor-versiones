CREATE OR REPLACE FUNCTION public.amprestadorconvenio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestadorconvenio(NEW);
        return NEW;
    END;
    $function$
