CREATE OR REPLACE FUNCTION public.ampersona_token()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpersona_token(NEW);
        return NEW;
    END;
    $function$
