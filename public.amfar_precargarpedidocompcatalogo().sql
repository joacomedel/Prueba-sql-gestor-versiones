CREATE OR REPLACE FUNCTION public.amfar_precargarpedidocompcatalogo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargarpedidocompcatalogo(NEW);
        return NEW;
    END;
    $function$
