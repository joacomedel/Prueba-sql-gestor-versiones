CREATE OR REPLACE FUNCTION public.aefichamedicaitememisiones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaitememisiones(OLD);
        return OLD;
    END;
    $function$
