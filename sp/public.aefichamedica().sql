CREATE OR REPLACE FUNCTION public.aefichamedica()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedica(OLD);
        return OLD;
    END;
    $function$
