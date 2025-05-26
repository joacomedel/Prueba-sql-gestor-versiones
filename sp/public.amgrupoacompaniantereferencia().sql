CREATE OR REPLACE FUNCTION public.amgrupoacompaniantereferencia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccgrupoacompaniantereferencia(NEW);
        return NEW;
    END;
    $function$
