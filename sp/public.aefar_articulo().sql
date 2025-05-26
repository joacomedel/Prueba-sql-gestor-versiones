CREATE OR REPLACE FUNCTION public.aefar_articulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articulo(OLD);
        return OLD;
    END;
    $function$
