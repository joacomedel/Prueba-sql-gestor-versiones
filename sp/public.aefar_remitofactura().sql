CREATE OR REPLACE FUNCTION public.aefar_remitofactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_remitofactura(OLD);
        return OLD;
    END;
    $function$
