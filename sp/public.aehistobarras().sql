CREATE OR REPLACE FUNCTION public.aehistobarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcchistobarras(OLD);
        return OLD;
    END;
    $function$
