CREATE OR REPLACE FUNCTION public.aefar_liquidacionitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacionitems(OLD);
        return OLD;
    END;
    $function$
