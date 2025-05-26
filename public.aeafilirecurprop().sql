CREATE OR REPLACE FUNCTION public.aeafilirecurprop()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilirecurprop(OLD);
        return OLD;
    END;
    $function$
