CREATE OR REPLACE FUNCTION public.aefar_pedido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_pedido(OLD);
        return OLD;
    END;
    $function$
