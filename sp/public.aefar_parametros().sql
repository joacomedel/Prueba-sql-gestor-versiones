CREATE OR REPLACE FUNCTION public.aefar_parametros()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_parametros(OLD);
        return OLD;
    END;
    $function$
