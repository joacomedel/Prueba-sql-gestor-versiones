CREATE OR REPLACE FUNCTION public.aefar_precargarpedidotraza()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargarpedidotraza(OLD);
        return OLD;
    END;
    $function$
