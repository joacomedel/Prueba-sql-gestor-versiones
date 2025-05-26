CREATE OR REPLACE FUNCTION public.amlaboratorio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcclaboratorio(NEW);
        return NEW;
    END;
    $function$
