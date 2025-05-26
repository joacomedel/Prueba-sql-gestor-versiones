CREATE OR REPLACE FUNCTION public.aemotivodebito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmotivodebito(OLD);
        return OLD;
    END;
    $function$
