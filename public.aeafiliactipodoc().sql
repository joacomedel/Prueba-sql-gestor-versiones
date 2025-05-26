CREATE OR REPLACE FUNCTION public.aeafiliactipodoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafiliactipodoc(OLD);
        return OLD;
    END;
    $function$
