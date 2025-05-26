CREATE OR REPLACE FUNCTION public.aebarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccbarras(OLD);
        return OLD;
    END;
    $function$
