CREATE OR REPLACE FUNCTION public.amordenodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenodonto(NEW);
        return NEW;
    END;
    $function$
