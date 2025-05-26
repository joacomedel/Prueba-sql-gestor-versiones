CREATE OR REPLACE FUNCTION public.amfar_precargapedido_articulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargapedido_articulo(NEW);
        return NEW;
    END;
    $function$
