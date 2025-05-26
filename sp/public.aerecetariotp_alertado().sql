CREATE OR REPLACE FUNCTION public.aerecetariotp_alertado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetariotp_alertado(OLD);
        return OLD;
    END;
    $function$
