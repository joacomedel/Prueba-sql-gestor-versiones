CREATE OR REPLACE FUNCTION public.aelibroconrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcclibroconrecibo(OLD);
        return OLD;
    END;
    $function$
