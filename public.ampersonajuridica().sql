CREATE OR REPLACE FUNCTION public.ampersonajuridica()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpersonajuridica(NEW);
        return NEW;
    END;
    $function$
