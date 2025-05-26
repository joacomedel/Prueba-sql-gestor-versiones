CREATE OR REPLACE FUNCTION public.aefar_liquidacionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacionestado(OLD);
        return OLD;
    END;
    $function$
