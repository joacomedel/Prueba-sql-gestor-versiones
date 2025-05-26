CREATE OR REPLACE FUNCTION public.aedebitofacturaprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdebitofacturaprestador(OLD);
        return OLD;
    END;
    $function$
