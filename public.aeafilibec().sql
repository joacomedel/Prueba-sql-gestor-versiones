CREATE OR REPLACE FUNCTION public.aeafilibec()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilibec(OLD);
        return OLD;
    END;
    $function$
