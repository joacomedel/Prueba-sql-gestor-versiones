CREATE OR REPLACE FUNCTION public.aefar_precargarpedido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_precargarpedido(OLD);
        return OLD;
    END;
    $function$
