CREATE OR REPLACE FUNCTION public.aeformapagofactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccformapagofactura(OLD);
        return OLD;
    END;
    $function$
