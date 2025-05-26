CREATE OR REPLACE FUNCTION public.amfar_precargarpedidocomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargarpedidocomprobante(NEW);
        return NEW;
    END;
    $function$
