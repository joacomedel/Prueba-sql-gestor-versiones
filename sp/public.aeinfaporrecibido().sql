CREATE OR REPLACE FUNCTION public.aeinfaporrecibido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinfaporrecibido(OLD);
        return OLD;
    END;
    $function$
