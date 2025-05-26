CREATE OR REPLACE FUNCTION public.amanticiporeintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccanticiporeintegro(NEW);
        return NEW;
    END;
    $function$
