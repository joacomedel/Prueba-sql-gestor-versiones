CREATE OR REPLACE FUNCTION public.aepersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpersona(OLD);
        return OLD;
    END;
    $function$
