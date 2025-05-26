CREATE OR REPLACE FUNCTION public.aefar_estado_validador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_estado_validador(OLD);
        return OLD;
    END;
    $function$
