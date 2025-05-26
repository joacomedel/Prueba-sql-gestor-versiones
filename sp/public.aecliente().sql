CREATE OR REPLACE FUNCTION public.aecliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccliente(OLD);
        return OLD;
    END;
    $function$
