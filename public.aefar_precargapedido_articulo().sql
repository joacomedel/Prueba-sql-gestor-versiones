CREATE OR REPLACE FUNCTION public.aefar_precargapedido_articulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargapedido_articulo(OLD);
        return OLD;
    END;
    $function$
