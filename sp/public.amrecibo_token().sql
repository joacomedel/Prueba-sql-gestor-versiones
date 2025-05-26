CREATE OR REPLACE FUNCTION public.amrecibo_token()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibo_token(NEW);
        return NEW;
    END;
    $function$
