CREATE OR REPLACE FUNCTION public.aefichamedicaitemodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaitemodonto(OLD);
        return OLD;
    END;
    $function$
