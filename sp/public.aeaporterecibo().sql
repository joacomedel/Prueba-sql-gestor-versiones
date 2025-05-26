CREATE OR REPLACE FUNCTION public.aeaporterecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaporterecibo(OLD);
        return OLD;
    END;
    $function$
