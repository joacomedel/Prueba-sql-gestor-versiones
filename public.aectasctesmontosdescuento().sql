CREATE OR REPLACE FUNCTION public.aectasctesmontosdescuento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctasctesmontosdescuento(OLD);
        return OLD;
    END;
    $function$
