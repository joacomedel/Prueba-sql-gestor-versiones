CREATE OR REPLACE FUNCTION public.amordenrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenrecibo(NEW);
        return NEW;
    END;
    $function$
