CREATE OR REPLACE FUNCTION public.aefar_movimientostock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostock(OLD);
        return OLD;
    END;
    $function$
