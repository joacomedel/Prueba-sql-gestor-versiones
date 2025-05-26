CREATE OR REPLACE FUNCTION public.aepersona_token()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpersona_token(OLD);
        return OLD;
    END;
    $function$
