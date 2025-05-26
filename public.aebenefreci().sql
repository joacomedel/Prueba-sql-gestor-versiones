CREATE OR REPLACE FUNCTION public.aebenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccbenefreci(OLD);
        return OLD;
    END;
    $function$
