CREATE OR REPLACE FUNCTION public.aerecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibo(OLD);
        return OLD;
    END;
    $function$
