CREATE OR REPLACE FUNCTION public.ampersonajuridicabis()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpersonajuridicabis(NEW);
        return NEW;
    END;
    $function$
