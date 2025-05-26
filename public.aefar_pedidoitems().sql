CREATE OR REPLACE FUNCTION public.aefar_pedidoitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_pedidoitems(OLD);
        return OLD;
    END;
    $function$
