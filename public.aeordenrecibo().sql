CREATE OR REPLACE FUNCTION public.aeordenrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenrecibo(OLD);
        return OLD;
    END;
    $function$
