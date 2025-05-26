CREATE OR REPLACE FUNCTION public.aeconcepto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconcepto(OLD);
        return OLD;
    END;
    $function$
