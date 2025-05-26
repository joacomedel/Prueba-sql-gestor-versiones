CREATE OR REPLACE FUNCTION public.amprestadortiporetencion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestadortiporetencion(NEW);
        return NEW;
    END;
    $function$
