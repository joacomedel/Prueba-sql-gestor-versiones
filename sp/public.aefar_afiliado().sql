CREATE OR REPLACE FUNCTION public.aefar_afiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_afiliado(OLD);
        return OLD;
    END;
    $function$
