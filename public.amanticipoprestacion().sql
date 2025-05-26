CREATE OR REPLACE FUNCTION public.amanticipoprestacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccanticipoprestacion(NEW);
        return NEW;
    END;
    $function$
