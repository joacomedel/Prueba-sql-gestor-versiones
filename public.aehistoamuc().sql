CREATE OR REPLACE FUNCTION public.aehistoamuc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcchistoamuc(OLD);
        return OLD;
    END;
    $function$
