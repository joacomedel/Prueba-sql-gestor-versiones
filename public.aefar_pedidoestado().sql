CREATE OR REPLACE FUNCTION public.aefar_pedidoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_pedidoestado(OLD);
        return OLD;
    END;
    $function$
