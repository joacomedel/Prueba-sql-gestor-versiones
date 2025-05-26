CREATE OR REPLACE FUNCTION public.amprestadorctacte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestadorctacte(NEW);
        return NEW;
    END;
    $function$
