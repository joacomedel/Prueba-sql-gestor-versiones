CREATE OR REPLACE FUNCTION public.amhistoamuc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcchistoamuc(NEW);
        return NEW;
    END;
    $function$
