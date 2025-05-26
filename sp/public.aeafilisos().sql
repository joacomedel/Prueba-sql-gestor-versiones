CREATE OR REPLACE FUNCTION public.aeafilisos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilisos(OLD);
        return OLD;
    END;
    $function$
