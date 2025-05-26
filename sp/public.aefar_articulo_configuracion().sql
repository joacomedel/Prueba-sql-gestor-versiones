CREATE OR REPLACE FUNCTION public.aefar_articulo_configuracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articulo_configuracion(OLD);
        return OLD;
    END;
    $function$
