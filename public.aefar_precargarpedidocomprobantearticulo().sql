CREATE OR REPLACE FUNCTION public.aefar_precargarpedidocomprobantearticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargarpedidocomprobantearticulo(OLD);
        return OLD;
    END;
    $function$
