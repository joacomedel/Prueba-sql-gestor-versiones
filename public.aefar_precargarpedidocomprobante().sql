CREATE OR REPLACE FUNCTION public.aefar_precargarpedidocomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargarpedidocomprobante(OLD);
        return OLD;
    END;
    $function$
