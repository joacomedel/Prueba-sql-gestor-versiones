CREATE OR REPLACE FUNCTION public.aeformas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccformas(OLD);
        return OLD;
    END;
    $function$
