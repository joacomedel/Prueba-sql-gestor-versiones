CREATE OR REPLACE FUNCTION public.aefar_parametrosvalores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_parametrosvalores(OLD);
        return OLD;
    END;
    $function$
