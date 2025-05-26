CREATE OR REPLACE FUNCTION public.amfar_articulo_configuracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articulo_configuracion(NEW);
        return NEW;
    END;
    $function$
