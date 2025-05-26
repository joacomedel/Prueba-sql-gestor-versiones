CREATE OR REPLACE FUNCTION public.aefar_precargarpedidocompcatalogo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargarpedidocompcatalogo(OLD);
        return OLD;
    END;
    $function$
