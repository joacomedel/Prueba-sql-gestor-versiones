CREATE OR REPLACE FUNCTION public.amhistobarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcchistobarras(NEW);
        return NEW;
    END;
    $function$
