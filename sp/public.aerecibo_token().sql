CREATE OR REPLACE FUNCTION public.aerecibo_token()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibo_token(OLD);
        return OLD;
    END;
    $function$
