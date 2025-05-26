CREATE OR REPLACE FUNCTION public.aepagosafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpagosafiliado(OLD);
        return OLD;
    END;
    $function$
