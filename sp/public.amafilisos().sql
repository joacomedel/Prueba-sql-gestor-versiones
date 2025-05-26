CREATE OR REPLACE FUNCTION public.amafilisos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilisos(NEW);
        return NEW;
    END;
    $function$
