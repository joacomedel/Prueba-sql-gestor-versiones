CREATE OR REPLACE FUNCTION public.aeaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaporte(OLD);
        return OLD;
    END;
    $function$
