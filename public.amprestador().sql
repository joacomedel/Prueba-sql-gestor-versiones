CREATE OR REPLACE FUNCTION public.amprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestador(NEW);
        return NEW;
    END;
    $function$
