CREATE OR REPLACE FUNCTION public.amordenanuladamotivo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenanuladamotivo(NEW);
        return NEW;
    END;
    $function$
