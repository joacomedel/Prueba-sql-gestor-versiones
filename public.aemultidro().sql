CREATE OR REPLACE FUNCTION public.aemultidro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmultidro(OLD);
        return OLD;
    END;
    $function$
