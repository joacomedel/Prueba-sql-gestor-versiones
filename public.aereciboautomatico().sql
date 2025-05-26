CREATE OR REPLACE FUNCTION public.aereciboautomatico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreciboautomatico(OLD);
        return OLD;
    END;
    $function$
