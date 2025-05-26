CREATE OR REPLACE FUNCTION public.aeimportesrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccimportesrecibo(OLD);
        return OLD;
    END;
    $function$
