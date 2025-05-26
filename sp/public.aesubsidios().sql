CREATE OR REPLACE FUNCTION public.aesubsidios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccsubsidios(OLD);
        return OLD;
    END;
    $function$
