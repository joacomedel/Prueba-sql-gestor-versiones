CREATE OR REPLACE FUNCTION public.amgrupoacompaniante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccgrupoacompaniante(NEW);
        return NEW;
    END;
    $function$
