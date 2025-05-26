CREATE OR REPLACE FUNCTION public.aeordenodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenodonto(OLD);
        return OLD;
    END;
    $function$
