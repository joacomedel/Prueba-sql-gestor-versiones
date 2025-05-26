CREATE OR REPLACE FUNCTION public.aefar_pedidoreclibrofact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_pedidoreclibrofact(OLD);
        return OLD;
    END;
    $function$
